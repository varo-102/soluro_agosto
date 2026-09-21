import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cotizacion_model.dart';
import '../../repositories/data_repository.dart';
import '../../repositories/repository_provider.dart';
import '../../theme/app_colors.dart';
import 'cotizacion_pdf_preview_screen.dart';

class CotizacionHistoryScreen extends StatefulWidget {
  final DataRepository? repository;

  const CotizacionHistoryScreen({super.key, this.repository});

  @override
  State<CotizacionHistoryScreen> createState() =>
      _CotizacionHistoryScreenState();
}

class _CotizacionHistoryScreenState extends State<CotizacionHistoryScreen> {
  DataRepository get _repository =>
      widget.repository ?? RepositoryProvider.instance;

  List<CotizacionModel> _cotizaciones = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCotizaciones();
  }

  Future<void> _loadCotizaciones() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getCotizaciones();
      if (mounted) {
        setState(() {
          _cotizaciones = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando historial: $e')),
        );
      }
    }
  }

  Future<void> _deleteCotizacion(CotizacionModel cotizacion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cotización'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${cotizacion.titulo}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.statusRedText,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteCotizacion(cotizacion.id);
      _loadCotizaciones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cotización "${cotizacion.titulo}" eliminada'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _duplicateCotizacion(CotizacionModel cotizacion) async {
    try {
      final duplicated = await _repository.duplicateCotizacion(cotizacion.id);
      await _loadCotizaciones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.azulProfundo,
            content: Text('Cotización duplicada: "${duplicated.titulo}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al duplicar cotización: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _searchQuery.trim().isEmpty
        ? _cotizaciones
        : _cotizaciones.where((c) {
            final q = _searchQuery.toLowerCase();
            return c.titulo.toLowerCase().contains(q) ||
                c.notas.toLowerCase().contains(q) ||
                c.articulos.any((a) => a.descripcion.toLowerCase().contains(q));
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surfaceMuted,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historial de Cotizaciones',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.azulProfundo,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.azulProfundo),
            )
          : Column(
              children: [
                // Cabecera con contador y buscador rápido
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        '${filteredList.length} ${filteredList.length == 1 ? "Cotización encontrada" : "Cotizaciones encontradas"}',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Campo de búsqueda compacto
                      SizedBox(
                        width: 150,
                        height: 36,
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Filtrar...',
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 16),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E2E2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E2E2)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de cotizaciones pasadas
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 56,
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _cotizaciones.isEmpty
                                    ? 'No hay cotizaciones guardadas'
                                    : 'No se encontraron resultados',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cot = filteredList[index];
                            String formattedDate;
                            try {
                              formattedDate = DateFormat('dd MMM yyyy', 'es_ES').format(cot.updatedAt);
                            } catch (_) {
                              formattedDate = DateFormat('dd/MM/yyyy').format(cot.updatedAt);
                            }

                            // Resumen de descripción o artículos
                            String snippet = cot.notas.trim();
                            if (snippet.isEmpty) {
                              final validItems = cot.articulosValidos;
                              if (validItems.isNotEmpty) {
                                snippet = validItems
                                    .map((a) => a.descripcion.isNotEmpty
                                        ? a.descripcion
                                        : 'Artículo #${a.orden}')
                                    .take(2)
                                    .join(', ');
                              } else {
                                snippet = 'Cotización sin descripción registrada';
                              }
                            }

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // Seleccionar cotización y volver a pantalla principal
                                Navigator.pop(context, cot);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.azulProfundo
                                          .withValues(alpha: 0.05),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF43474D)
                                        : const Color(0xFFE8E8E8),
                                  ),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Fila Título y Fecha
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          cot.titulo,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.amarilloSol
                                                : AppColors.azulProfundo,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.surfaceDark
                                                : AppColors.surfaceMuted,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                      .textSecondaryLight,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Descripción / Notas
                                    Text(
                                      snippet,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Chip de Fotos adjuntas
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF314865)
                                                .withValues(alpha: 0.3)
                                            : const Color(0xFFD2E4FF)
                                                .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.photo_library_outlined,
                                            size: 13,
                                            color: AppColors.azulProfundo,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${cot.fotos.length} fotos adjuntas',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.azulProfundo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),

                                    // Fila de Botones: Compartir, Duplicar, Eliminar
                                    Row(
                                      children: [
                                        // Botón Compartir
                                        Expanded(
                                          child: SizedBox(
                                            height: 36,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CotizacionPdfPreviewScreen(
                                                      cotizacion: cot,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.share,
                                                  size: 15),
                                              label: const Text('Compartir'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.azulProfundo,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Botón Duplicar
                                        Expanded(
                                          child: SizedBox(
                                            height: 36,
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _duplicateCotizacion(cot),
                                              icon: const Icon(
                                                  Icons.content_copy,
                                                  size: 15),
                                              label: const Text('Duplicar'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.azulProfundo,
                                                side: const BorderSide(
                                                    color:
                                                        AppColors.azulProfundo),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Botón Eliminar
                                        SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                _deleteCotizacion(cot),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.statusRedText,
                                              side: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: AppColors.statusRedText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
