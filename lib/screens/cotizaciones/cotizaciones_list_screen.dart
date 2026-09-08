import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/cotizacion_model.dart';
import '../../models/articulo_cotizacion_model.dart';
import '../../models/imagen_cotizacion_model.dart';
import '../../repositories/data_repository.dart';
import '../../repositories/repository_provider.dart';
import '../../services/file_storage_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../theme/app_colors.dart';
import 'cotizacion_form_screen.dart';

class CotizacionesListScreen extends StatefulWidget {
  final DataRepository? repository;

  const CotizacionesListScreen({super.key, this.repository});

  @override
  State<CotizacionesListScreen> createState() => _CotizacionesListScreenState();
}

class _CotizacionesListScreenState extends State<CotizacionesListScreen> {
  DataRepository get _repository => widget.repository ?? RepositoryProvider.instance;
  
  List<CotizacionWithDetails> _cotizacionesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCotizaciones();
  }

  Future<void> _loadCotizaciones() async {
    setState(() { _isLoading = true; });

    final cotizaciones = await _repository.getCotizaciones();
    List<CotizacionWithDetails> loaded = [];

    for (var c in cotizaciones) {
      final articulos = await _repository.getArticulosPorCotizacion(c.id);
      final imagenes = await _repository.getImagenesPorCotizacion(c.id);
      loaded.add(CotizacionWithDetails(cotizacion: c, articulos: articulos, imagenes: imagenes));
    }

    setState(() {
      _cotizacionesList = loaded;
      _isLoading = false;
    });
  }

  Future<void> _deleteCotizacion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cotización'),
        content: const Text('¿Estás seguro de que deseas eliminar esta cotización y sus imágenes físicamente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusRedText),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteCotizacion(id); // Delete from DB
      await FileStorageService().deleteCotizacionDirectory(id); // Delete physical folder
      _loadCotizaciones();
    }
  }

  Future<void> _duplicateCotizacion(CotizacionWithDetails item) async {
    final newId = const Uuid().v4();
    final newCotizacion = item.cotizacion.copyWith(
      id: newId,
      titulo: '${item.cotizacion.titulo} (copia)',
      fechaCreacion: DateTime.now(),
      fechaModificacion: DateTime.now(),
    );

    // Duplicar físicamente archivos
    await FileStorageService().duplicateCotizacionDirectory(item.cotizacion.id, newId);

    // Copiar artículos
    final newArticulos = item.articulos.map((a) => a.copyWith(
      id: const Uuid().v4(),
      cotizacionId: newId,
    )).toList();

    // Copiar imágenes (referencias BD)
    final newImagenes = item.imagenes.map((i) {
      // Solo actualizamos la parte del directorio en la ruta.
      final newRutaLocal = i.rutaLocal.replaceAll(item.cotizacion.id, newId);

      return i.copyWith(
        id: const Uuid().v4(),
        cotizacionId: newId,
        rutaLocal: newRutaLocal,
      );
    }).toList();

    await _repository.saveCotizacionCompleta(newCotizacion, newArticulos, newImagenes);
    _loadCotizaciones();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización duplicada con éxito')),
      );
    }
  }
  
  Future<void> _shareCotizacion(CotizacionWithDetails item) async {
    // Generar PDF y compartirlo
    await PdfGeneratorService().generarYCompartirCotizacion(
      cotizacion: item.cotizacion,
      articulos: item.articulos,
      imagenes: item.imagenes,
    );
  }

  void _openForm([String? cotizacionId]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CotizacionFormScreen(
          cotizacionId: cotizacionId,
          repository: _repository,
        ),
      ),
    );
    _loadCotizaciones(); // Refresh upon return
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy', 'es_ES');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.azulProfundo));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Historial de Cotizaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCotizaciones,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_cotizacionesList.length} Cotizaciones encontradas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text('Filtrar'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : AppColors.azulProfundo,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: _cotizacionesList.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.request_quote_outlined,
                              size: 72,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No tienes cotizaciones guardadas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _openForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amarilloSol,
                                foregroundColor: AppColors.azulProfundo,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Nueva Cotización', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _cotizacionesList.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: ElevatedButton.icon(
                                onPressed: _openForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.amarilloSol,
                                  foregroundColor: AppColors.azulProfundo,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 24),
                                label: const Text(
                                  'Nueva Cotización',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }

                          final item = _cotizacionesList[index];
                          final cotizacion = item.cotizacion;
                          
                          final notasResumen = cotizacion.notasAdicionales.isNotEmpty 
                            ? cotizacion.notasAdicionales 
                            : 'Cotización sin descripción adicional.';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05)),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: const Color(0xFF0A2540).withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 4),
                                  )
                              ]
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openForm(cotizacion.id),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cotizacion.titulo,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : AppColors.azulProfundo,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.grey.shade800 : AppColors.surfaceMuted,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              dateFormat.format(cotizacion.fechaModificacion),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        notasResumen,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFFB0C8EB).withValues(alpha: 0.1) : const Color(0xFFB0C8EB).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.photo_library, size: 15, color: isDark ? const Color(0xFFD2E4FF) : AppColors.azulProfundo),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${item.imagenes.length} fotos adjuntas',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? const Color(0xFFD2E4FF) : AppColors.azulProfundo,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.only(top: 10),
                                        decoration: BoxDecoration(
                                          border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : AppColors.surfaceMuted)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _shareCotizacion(item),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isDark ? Colors.white : AppColors.azulProfundo,
                                                  foregroundColor: isDark ? AppColors.azulProfundo : Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(vertical: 0),
                                                  minimumSize: const Size(0, 36),
                                                ),
                                                icon: const Icon(Icons.share, size: 18),
                                                label: const Text('Compartir', style: TextStyle(fontWeight: FontWeight.w500)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _duplicateCotizacion(item),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: isDark ? Colors.white : AppColors.azulProfundo,
                                                  side: BorderSide(color: isDark ? Colors.white : AppColors.azulProfundo),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(vertical: 0),
                                                  minimumSize: const Size(0, 36),
                                                ),
                                                icon: const Icon(Icons.content_copy, size: 18),
                                                label: const Text('Duplicar', style: TextStyle(fontWeight: FontWeight.w500)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: OutlinedButton(
                                                onPressed: () => _deleteCotizacion(cotizacion.id),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                  side: BorderSide(color: isDark ? Colors.grey.shade800 : AppColors.surfaceMuted),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                child: const Icon(Icons.delete, size: 18),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _cotizacionesList.length + 1,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CotizacionWithDetails {
  final CotizacionModel cotizacion;
  final List<ArticuloCotizacionModel> articulos;
  final List<ImagenCotizacionModel> imagenes;

  CotizacionWithDetails({
    required this.cotizacion,
    required this.articulos,
    required this.imagenes,
  });
}
