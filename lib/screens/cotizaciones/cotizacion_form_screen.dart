import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/cotizacion_model.dart';
import '../../models/articulo_cotizacion_model.dart';
import '../../models/imagen_cotizacion_model.dart';
import '../../repositories/data_repository.dart';
import '../../services/file_storage_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../theme/app_colors.dart';
import 'dart:io';

class CotizacionFormScreen extends StatefulWidget {
  final String? cotizacionId;
  final DataRepository repository;

  const CotizacionFormScreen({super.key, this.cotizacionId, required this.repository});

  @override
  State<CotizacionFormScreen> createState() => _CotizacionFormScreenState();
}

class _CotizacionFormScreenState extends State<CotizacionFormScreen> {
  bool _isLoading = true;
  Timer? _debounce;
  bool _isSaving = false;
  
  late CotizacionModel _cotizacion;
  late List<ArticuloCotizacionModel> _articulos;
  late List<ImagenCotizacionModel> _imagenes;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadOrCreate();
    
    _tituloController.addListener(_onFieldChanged);
    _notasController.addListener(_onFieldChanged);
  }

  Future<void> _loadOrCreate() async {
    setState(() { _isLoading = true; });
    if (widget.cotizacionId != null) {
      final loaded = await widget.repository.getCotizacionById(widget.cotizacionId!);
      if (loaded != null) {
        _cotizacion = loaded;
        _articulos = await widget.repository.getArticulosPorCotizacion(_cotizacion.id);
        _imagenes = await widget.repository.getImagenesPorCotizacion(_cotizacion.id);
      } else {
        _initNewState();
      }
    } else {
      _initNewState();
    }

    _tituloController.text = _cotizacion.titulo;
    _notasController.text = _cotizacion.notasAdicionales;

    setState(() {
      _isLoading = false;
    });
  }

  void _initNewState() {
    final newId = const Uuid().v4();
    _cotizacion = CotizacionModel(id: newId, titulo: 'Cotización ${_cotizacionesCount()}');
    _articulos = List.generate(7, (index) => ArticuloCotizacionModel(cotizacionId: newId));
    _imagenes = [];
    _tituloController.text = _cotizacion.titulo;
    _notasController.text = '';
  }

  int _cotizacionesCount() {
    // Just a placeholder, assuming you might want an incremental logic. Here just returning 1.
    return 1;
  }

  void _resetToNew() {
    setState(() {
      _initNewState();
    });
    _autoSave();
  }

  Future<void> _duplicateCurrent() async {
    await _autoSave();
    final newId = const Uuid().v4();
    final newCotizacion = _cotizacion.copyWith(
      id: newId,
      titulo: '${_cotizacion.titulo} (copia)',
      fechaCreacion: DateTime.now(),
      fechaModificacion: DateTime.now(),
    );

    await FileStorageService().duplicateCotizacionDirectory(_cotizacion.id, newId);

    final newArticulos = _articulos.map((a) => a.copyWith(id: const Uuid().v4(), cotizacionId: newId)).toList();
    final newImagenes = _imagenes.map((i) {
      final newRutaLocal = i.rutaLocal.replaceAll(_cotizacion.id, newId);
      return i.copyWith(id: const Uuid().v4(), cotizacionId: newId, rutaLocal: newRutaLocal);
    }).toList();

    await widget.repository.saveCotizacionCompleta(newCotizacion, newArticulos, newImagenes);

    setState(() {
      _cotizacion = newCotizacion;
      _articulos = newArticulos;
      _imagenes = newImagenes;
      _tituloController.text = _cotizacion.titulo;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cotización duplicada con éxito')));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tituloController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _autoSave();
    });
    setState(() {});
  }

  Future<void> _autoSave() async {
    setState(() { _isSaving = true; });

    _cotizacion = _cotizacion.copyWith(
      titulo: _tituloController.text.trim(),
      notasAdicionales: _notasController.text.trim(),
    );

    List<ArticuloCotizacionModel> toSave = [];
    for (var art in _articulos) {
      if (art.descripcion.trim().isNotEmpty) {
        toSave.add(art.copyWith(descripcion: art.descripcion.trim()));
      }
    }

    await widget.repository.saveCotizacionCompleta(_cotizacion, toSave, _imagenes);

    if (mounted) {
      setState(() { _isSaving = false; });
    }
  }

  void _addArticulo({int count = 1}) {
    if (_articulos.length >= 100) return;
    setState(() {
      for (int i = 0; i < count; i++) {
        _articulos.add(ArticuloCotizacionModel(cotizacionId: _cotizacion.id));
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imagenes.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Máximo 6 fotos permitidas.')));
      return;
    }

    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      setState(() { _isSaving = true; });
      final savedPath = await FileStorageService().saveCotizacionImage(_cotizacion.id, photo.path);
      if (savedPath != null) {
        setState(() {
          _imagenes.add(ImagenCotizacionModel(
            cotizacionId: _cotizacion.id,
            rutaLocal: savedPath,
          ));
        });
        _autoSave();
      } else {
        setState(() { _isSaving = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar la imagen.')));
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagenes.removeAt(index);
    });
    _autoSave();
  }

  Future<void> _generatePdf() async {
    await _autoSave();
    await PdfGeneratorService().generarYCompartirCotizacion(
      cotizacion: _cotizacion,
      articulos: _articulos,
      imagenes: _imagenes,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.azulProfundo)));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatCurrency = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final double total = _articulos.fold(0.0, (sum, item) => sum + item.subtotal);
    final int validArticulos = _articulos.where((a) => a.descripcion.trim().isNotEmpty).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Negociar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azulProfundo))),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // Top Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generatePdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : AppColors.azulProfundo,
                      foregroundColor: isDark ? AppColors.azulProfundo : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Compartir', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _duplicateCurrent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey.shade800 : AppColors.cardLight,
                      foregroundColor: isDark ? Colors.white : AppColors.azulProfundo,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.content_copy, size: 18),
                    label: const Text('Duplicar', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetToNew,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amarilloSol,
                      foregroundColor: AppColors.azulProfundo,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Table Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: AppColors.azulProfundo.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    )
                ]
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : AppColors.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade700 : AppColors.surfaceMuted)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tituloController,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.azulProfundo,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: 'Título Cotización',
                              hintStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondaryLight),
                            ),
                          ),
                        ),
                        Icon(Icons.edit, size: 18, color: isDark ? Colors.white54 : AppColors.textSecondaryLight),
                      ],
                    ),
                  ),
                  // Column Headers
                  Container(
                    color: isDark ? Colors.grey.shade900 : AppColors.surfaceMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(width: 24, child: Text('#', textAlign: TextAlign.center, style: _headerStyle(isDark))),
                        Expanded(flex: 3, child: Text('ARTÍCULO', style: _headerStyle(isDark))),
                        Expanded(flex: 1, child: Text('PRECIO', textAlign: TextAlign.right, style: _headerStyle(isDark))),
                        const SizedBox(width: 8),
                        Expanded(flex: 1, child: Text('CANT.', textAlign: TextAlign.center, style: _headerStyle(isDark))),
                        const SizedBox(width: 8),
                        SizedBox(width: 70, child: Text('SUBTOTAL', textAlign: TextAlign.right, style: _headerStyle(isDark, AppColors.azulProfundo))),
                      ],
                    ),
                  ),
                  // Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _articulos.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : AppColors.surfaceMuted),
                    itemBuilder: (context, index) => _buildArticuloRow(index, isDark, formatCurrency),
                  ),
                  // Footer Totals
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : AppColors.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                      border: Border(top: BorderSide(color: isDark ? Colors.grey.shade700 : AppColors.azulProfundo.withValues(alpha: 0.2), width: 2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? Colors.transparent : AppColors.azulProfundo.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                Text('TOTAL ARTÍCULOS', style: _headerStyle(isDark)),
                                const SizedBox(height: 2),
                                Text(validArticulos.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.azulProfundo)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? Colors.transparent : AppColors.azulProfundo.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                Text('MONTO TOTAL', style: _headerStyle(isDark)),
                                const SizedBox(height: 2),
                                Text('Bs. ${formatCurrency.format(total)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.azulProfundo)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons Row (Add Item, Add 5, Add Photos)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addArticulo(count: 1),
                    style: _bottomActionStyle(isDark),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Artículo', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addArticulo(count: 5),
                    style: _bottomActionStyle(isDark),
                    icon: const Icon(Icons.library_add, size: 18),
                    label: const Text('5 Arts.', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Tomar Foto'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                              ListTile(leading: const Icon(Icons.photo_library), title: const Text('Elegir de Galería'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                            ],
                          ),
                        ),
                      );
                    },
                    style: _bottomActionStyle(isDark),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Fotos', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notes Block
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.grey.shade800 : AppColors.azulProfundo.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTAS O INFORMACIÓN ADICIONAL', style: _headerStyle(isDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notasController,
                    maxLines: null,
                    minLines: 2,
                    style: TextStyle(fontSize: 16, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                    decoration: InputDecoration(
                      hintText: 'Escribe información o notas adicionales aquí...',
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade900 : AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Colors.transparent : AppColors.surfaceMuted),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Colors.transparent : AppColors.surfaceMuted),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.azulProfundo),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            
            // Image grid if any
            if (_imagenes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('FOTOS ADJUNTAS (${_imagenes.length})', style: _headerStyle(isDark)),
              ),
              const SizedBox(height: 8),
              _buildImagesGrid(),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle(bool isDark, [Color? overrideColor]) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: overrideColor ?? (isDark ? Colors.white70 : AppColors.textSecondaryLight),
    );
  }

  ButtonStyle _bottomActionStyle(bool isDark) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      foregroundColor: isDark ? Colors.white : AppColors.azulProfundo,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  Widget _buildArticuloRow(int index, bool isDark, NumberFormat formatCurrency) {
    final articulo = _articulos[index];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24, 
            child: Text('${index + 1}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : AppColors.textSecondaryLight)),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: articulo.descripcion,
              style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimaryLight),
              decoration: InputDecoration(
                isDense: true, 
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: InputBorder.none,
                hintText: 'Descripción',
                hintStyle: TextStyle(color: isDark ? Colors.white24 : AppColors.textSecondaryLight.withValues(alpha: 0.5)),
              ),
              onChanged: (val) {
                _articulos[index] = articulo.copyWith(descripcion: val);
                _onFieldChanged();
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: articulo.precio == 0 ? '' : articulo.precio.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'monospace', color: isDark ? Colors.white : AppColors.textPrimaryLight),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                isDense: true, 
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle: TextStyle(color: isDark ? Colors.white24 : AppColors.textSecondaryLight.withValues(alpha: 0.5)),
              ),
              onChanged: (val) {
                _articulos[index] = articulo.copyWith(precio: double.tryParse(val) ?? 0.0);
                _onFieldChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextFormField(
                initialValue: articulo.cantidad == 0 ? '' : articulo.cantidad.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace', color: isDark ? Colors.white : AppColors.textPrimaryLight),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  isDense: true, 
                  contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  border: InputBorder.none,
                  hintText: '0.00',
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                ),
                onChanged: (val) {
                  _articulos[index] = articulo.copyWith(cantidad: double.tryParse(val) ?? 0.0);
                  _onFieldChanged();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 70,
            alignment: Alignment.centerRight,
            child: Text(
              formatCurrency.format(articulo.subtotal),
              style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _imagenes.asMap().entries.map((entry) {
        int idx = entry.key;
        ImagenCotizacionModel img = entry.value;
        return Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(File(img.rutaLocal)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _removeImage(idx),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            )
          ],
        );
      }).toList(),
    );
  }
}
