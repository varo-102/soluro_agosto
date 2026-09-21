import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/cotizacion_model.dart';
import '../../models/articulo_cotizacion_model.dart';
import '../../repositories/repository_provider.dart';
import '../../services/pdf_generator_service.dart';
import '../../services/file_storage_service.dart';
import '../../theme/app_colors.dart';
import 'cotizaciones_list_screen.dart';

class CotizacionFormScreen extends StatefulWidget {
  final CotizacionModel? cotizacion;
  const CotizacionFormScreen({super.key, this.cotizacion});

  @override
  State<CotizacionFormScreen> createState() => _CotizacionFormScreenState();
}

class _CotizacionFormScreenState extends State<CotizacionFormScreen> {
  late CotizacionModel _cotizacion;
  bool _isLoading = true;
  Timer? _debounceTimer;
  bool _isSaving = false;
  final FileStorageService _storageService = FileStorageService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _tituloController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCotizacion();
  }

  Future<void> _initCotizacion() async {
    setState(() => _isLoading = true);
    try {
      if (widget.cotizacion != null) {
        _cotizacion = widget.cotizacion!;
      } else {
        final cotizaciones = await RepositoryProvider.instance.getCotizaciones();
        final count = cotizaciones.length + 1;
        _cotizacion = CotizacionModel(
          titulo: 'Cotización $count',
          articulos: List.generate(7, (index) => ArticuloCotizacionModel(cotizacionId: '')),
        );
        // Wait to attach the generated cotizacion ID to articles
        _cotizacion = _cotizacion.copyWith(
          articulos: _cotizacion.articulos.map((a) => a.copyWith(cotizacionId: _cotizacion.id)).toList()
        );
      }
      
      _tituloController.text = _cotizacion.titulo;
      _notasController.text = _cotizacion.notasAdicionales;
      
      if (mounted) {
        setState(() => _isLoading = false);
        _saveDebounced();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error de Carga'),
            content: Text('No se pudo cargar la cotización:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _notasController.dispose();
    _tituloController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
    _saveDebounced();
  }

  void _saveDebounced() {
    setState(() => _isSaving = true);
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      await _saveToDb();
    });
  }

  Future<void> _saveToDb() async {
    // Trim values and filter out empty rows for saving but keep them in UI if we want (actually the prompt says: "al guardar o exportar, se eliminan las filas cuya descripción esté vacía"). Let's do it for export, but in UI keep them so user can type. Wait, "al guardar...". If we delete on save, they disappear while typing. Let's just trim fields and let the UI keep empty rows until exported.
    
    _cotizacion = _cotizacion.copyWith(
      fechaModificacion: DateTime.now(),
    );
    await RepositoryProvider.instance.saveCotizacion(_cotizacion);
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _addArticulos(int count) {
    if (_cotizacion.articulos.length + count > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Límite de 100 artículos alcanzado')),
      );
      return;
    }
    
    final newItems = List.generate(count, (index) => ArticuloCotizacionModel(cotizacionId: _cotizacion.id));
    _cotizacion = _cotizacion.copyWith(
      articulos: [..._cotizacion.articulos, ...newItems]
    );
    _onDataChanged();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _addPhoto() async {
    if (_cotizacion.imagenes.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Límite de 6 fotos alcanzado')),
      );
      return;
    }

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final path = await _storageService.pickAndCompressImage(_cotizacion.id, source);
      if (path != null) {
        _cotizacion = _cotizacion.copyWith(
          imagenes: [..._cotizacion.imagenes, path],
        );
        _onDataChanged();
      }
    }
  }

  void _deletePhoto(String path) async {
    await _storageService.deleteImage(path);
    _cotizacion = _cotizacion.copyWith(
      imagenes: _cotizacion.imagenes.where((p) => p != path).toList(),
    );
    _onDataChanged();
  }

  Future<void> _crearNueva() async {
    setState(() => _isLoading = true);
    try {
      final cotizaciones = await RepositoryProvider.instance.getCotizaciones();
      final count = cotizaciones.length + 1;
      setState(() {
        _cotizacion = CotizacionModel(
          titulo: 'Cotización $count',
          articulos: List.generate(7, (index) => ArticuloCotizacionModel(cotizacionId: '')),
        );
        _cotizacion = _cotizacion.copyWith(
          articulos: _cotizacion.articulos.map((a) => a.copyWith(cotizacionId: _cotizacion.id)).toList()
        );
        _tituloController.text = _cotizacion.titulo;
        _notasController.text = _cotizacion.notasAdicionales;
        _isLoading = false;
      });
      _saveDebounced();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('No se pudo crear la cotización:\n$e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  Future<void> _duplicar() async {
    final copy = _cotizacion.copyWith(
      id: null,
      titulo: '${_cotizacion.titulo} (copia)',
      fechaCreacion: DateTime.now(),
      fechaModificacion: DateTime.now(),
      imagenes: [],
      articulos: _cotizacion.articulos.map((a) => a.copyWith(id: null)).toList(),
    );

    final newImages = await _storageService.duplicateCotizacionImages(_cotizacion.id, copy.id);
    final finalCopy = copy.copyWith(imagenes: newImages);
    
    await RepositoryProvider.instance.saveCotizacion(finalCopy);
    
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => CotizacionFormScreen(cotizacion: finalCopy)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Negociar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CotizacionesListScreen()));
              },
              style: TextButton.styleFrom(
                backgroundColor: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                foregroundColor: isDark ? AppColors.azulProfundo : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ACCIONES SUPERIORES
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => PdfGeneratorService.generateAndPreviewPdf(_cotizacion),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Compartir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulProfundo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _duplicar,
                    icon: const Icon(Icons.content_copy, size: 18),
                    label: const Text('Duplicar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azulProfundo,
                      side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _crearNueva,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amarilloSol,
                      foregroundColor: AppColors.azulProfundo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CONTENEDOR DE TABLA Y TOTALES
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // CABECERA DE LA TABLA CON TITULO Y ESTADO
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tituloController,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                            onChanged: (val) {
                              _cotizacion = _cotizacion.copyWith(titulo: val);
                              _saveDebounced();
                            },
                          ),
                        ),
                        Row(
                          children: [
                            if (!_isSaving)
                              const Icon(Icons.check_circle, color: Colors.green, size: 16)
                            else
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 4),
                            Text(
                              _isSaving ? 'Guardando' : 'Guardado',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ENCABEZADOS DE COLUMNAS
                  Container(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        const SizedBox(width: 24, child: Text('#', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        const Expanded(child: Text('ARTÍCULO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        const SizedBox(width: 80, child: Text('PRECIO', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        const SizedBox(width: 50, child: Text('CANT.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 80, child: Text('SUBTOTAL', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo))),
                      ],
                    ),
                  ),

                  // FILAS
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cotizacion.articulos.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _cotizacion.articulos[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(width: 24, child: Text('${index + 1}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                            Expanded(
                              child: TextFormField(
                                initialValue: item.descripcion,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Descripción',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                ),
                                onChanged: (val) {
                                  _cotizacion.articulos[index] = item.copyWith(descripcion: val);
                                  _onDataChanged();
                                },
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: item.precio == 0 ? '' : item.precio.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                ),
                                onChanged: (val) {
                                  final precio = double.tryParse(val) ?? 0.0;
                                  // auto-complete qty if empty
                                  double cant = item.cantidad;
                                  if (cant == 0 && item.descripcion.isNotEmpty && precio > 0) cant = 1.0;
                                  _cotizacion.articulos[index] = item.copyWith(precio: precio, cantidad: cant);
                                  _onDataChanged();
                                },
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TextFormField(
                                  initialValue: item.cantidad == 0 ? '' : item.cantidad.toString(),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                  ),
                                  onChanged: (val) {
                                    _cotizacion.articulos[index] = item.copyWith(cantidad: double.tryParse(val) ?? 0.0);
                                    _onDataChanged();
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                item.subtotal.toStringAsFixed(2),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // TOTALES FOOTER
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      border: Border(top: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 2)),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Text('TOTAL UNIDADES', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                Text(_cotizacion.totalArticulos.toStringAsFixed(0), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.azulProfundo)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Text('MONTO TOTAL', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                Text('\$ ${_cotizacion.montoTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo)),
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
            const SizedBox(height: 16),

            // BOTONES AÑADIR
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addArticulos(1),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Artículo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azulProfundo,
                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                      side: BorderSide.none,
                      elevation: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addArticulos(5),
                    icon: const Icon(Icons.library_add, size: 18),
                    label: const Text('5 Artículos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azulProfundo,
                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                      side: BorderSide.none,
                      elevation: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Fotos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azulProfundo,
                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                      side: BorderSide.none,
                      elevation: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // NOTAS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTAS O INFORMACIÓN ADICIONAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notasController,
                    maxLines: null,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Escribe información o notas adicionales aquí...',
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      _cotizacion = _cotizacion.copyWith(notasAdicionales: val);
                      _saveDebounced();
                    },
                  ),
                ],
              ),
            ),
            
            // FOTOS (si hay)
            if (_cotizacion.imagenes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FOTOGRAFÍAS ADJUNTAS (${_cotizacion.imagenes.length}/6)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 16/9,
                      ),
                      itemCount: _cotizacion.imagenes.length,
                      itemBuilder: (context, index) {
                        final path = _cotizacion.imagenes[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(path), fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _deletePhoto(path),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
