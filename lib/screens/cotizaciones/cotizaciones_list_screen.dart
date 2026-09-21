import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cotizacion_model.dart';
import '../../repositories/repository_provider.dart';
import '../../services/pdf_generator_service.dart';
import '../../services/file_storage_service.dart';
import '../../theme/app_colors.dart';
import 'cotizacion_form_screen.dart';

class CotizacionesListScreen extends StatefulWidget {
  const CotizacionesListScreen({super.key});

  @override
  State<CotizacionesListScreen> createState() => _CotizacionesListScreenState();
}

class _CotizacionesListScreenState extends State<CotizacionesListScreen> {
  bool _isLoading = true;
  List<CotizacionModel> _cotizaciones = [];
  final FileStorageService _storageService = FileStorageService();

  @override
  void initState() {
    super.initState();
    _loadCotizaciones();
  }

  Future<void> _loadCotizaciones() async {
    setState(() => _isLoading = true);
    final results = await RepositoryProvider.instance.getCotizaciones();
    setState(() {
      _cotizaciones = results;
      _isLoading = false;
    });
  }

  void _navigateToForm([CotizacionModel? cotizacion]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CotizacionFormScreen(cotizacion: cotizacion),
      ),
    );
    _loadCotizaciones();
  }

  Future<void> _duplicateCotizacion(CotizacionModel original) async {
    final copy = original.copyWith(
      id: null, // New UUID
      titulo: '${original.titulo} (copia)',
      fechaCreacion: DateTime.now(),
      fechaModificacion: DateTime.now(),
      imagenes: [], // Will populate after copy
      articulos: original.articulos.map((a) => a.copyWith(id: null)).toList(),
    );

    // Duplicate physical images
    final newImages = await _storageService.duplicateCotizacionImages(original.id, copy.id);
    final finalCopy = copy.copyWith(imagenes: newImages);

    await RepositoryProvider.instance.saveCotizacion(finalCopy);
    _loadCotizaciones();
  }

  Future<void> _deleteCotizacion(CotizacionModel cotizacion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cotización'),
        content: const Text('¿Estás seguro de que deseas eliminar esta cotización? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Hard delete as per prompt: "borrar registro... y borrar físicamente la carpeta"
      await RepositoryProvider.instance.hardDeleteCotizacion(cotizacion.id);
      await _storageService.deleteCotizacionFolder(cotizacion.id);
      _loadCotizaciones();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateFormat formatter = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Cotizaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cotizaciones.isEmpty
              ? const Center(child: Text('No hay cotizaciones guardadas'))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          '${_cotizaciones.length} Cotizaciones encontradas',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _cotizaciones.length,
                          itemBuilder: (context, index) {
                            final cot = _cotizaciones[index];
                            final firstArticulo = cot.articulos.isNotEmpty ? cot.articulos.first.descripcion : 'Sin artículos';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _navigateToForm(cot),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cot.titulo,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              formatter.format(cot.fechaModificacion),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        firstArticulo,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (cot.imagenes.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.azulProfundo.withValues(alpha: 0.5) : AppColors.azulProfundo.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.photo_library, size: 14, color: isDark ? Colors.white : AppColors.azulProfundo),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${cot.imagenes.length} fotos adjuntas',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white : AppColors.azulProfundo,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => PdfGeneratorService.generateAndPreviewPdf(cot),
                                              icon: const Icon(Icons.share, size: 18),
                                              label: const Text('Compartir'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.azulProfundo,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                minimumSize: const Size(0, 36),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _duplicateCotizacion(cot),
                                              icon: const Icon(Icons.content_copy, size: 18),
                                              label: const Text('Duplicar'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: isDark ? Colors.white : AppColors.azulProfundo,
                                                side: BorderSide(color: isDark ? Colors.white : AppColors.azulProfundo),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                minimumSize: const Size(0, 36),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _deleteCotizacion(cot),
                                            icon: const Icon(Icons.delete_outline),
                                            color: Colors.red,
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.red.withValues(alpha: 0.1),
                                              minimumSize: const Size(36, 36),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
