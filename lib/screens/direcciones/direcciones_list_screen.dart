import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/direccion_model.dart';
import '../../services/clipboard_service.dart';
import '../../services/database_helper.dart';
import '../../theme/app_colors.dart';
import 'add_direccion_modal.dart';

class DireccionesListScreen extends StatefulWidget {
  const DireccionesListScreen({super.key});

  @override
  State<DireccionesListScreen> createState() => _DireccionesListScreenState();
}

class _DireccionesListScreenState extends State<DireccionesListScreen> {
  List<DireccionModel> _direccionesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDirecciones();
  }

  Future<void> loadDirecciones() async {
    setState(() {
      _isLoading = true;
    });

    final list = await DatabaseHelper().getDirecciones();

    setState(() {
      _direccionesList = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteDireccion(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Dirección'),
        content: const Text('¿Estás seguro de que deseas eliminar esta dirección?'),
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
      await DatabaseHelper().deleteDireccion(id);
      loadDirecciones();
    }
  }

  Future<void> _openMaps(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace de Google Maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir enlace: $e')),
        );
      }
    }
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddDireccionModal(
        onDireccionSaved: loadDirecciones,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.azulProfundo),
      );
    }

    return RefreshIndicator(
      onRefresh: loadDirecciones,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _direccionesList.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size: 72,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes direcciones guardadas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Presiona "+ Añadir Dirección" para guardar tu primera ubicación.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amarilloSol,
                              foregroundColor: AppColors.azulProfundo,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir Dirección'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _direccionesList.length) {
                          // Bottom "+ Añadir Dirección" button
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ElevatedButton.icon(
                              onPressed: _showAddModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amarilloSol,
                                foregroundColor: AppColors.azulProfundo,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 24),
                              label: const Text(
                                'Añadir Dirección',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        final dir = _direccionesList[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.storefront,
                                            color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              dir.titulo,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? AppColors.textPrimaryDark : AppColors.azulProfundo,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 22),
                                      color: Colors.grey.shade600,
                                      onPressed: () => _deleteDireccion(dir.id!),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Detail
                                Text(
                                  dir.detalle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Maps Link Action & Copy Info Button
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openMaps(dir.urlMaps),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                                          ),
                                          foregroundColor: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                                        ),
                                        icon: const Icon(Icons.map_outlined, size: 18),
                                        label: const Text(
                                          'Abrir en Maps',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final textToCopy = dir.formattedCopyText;
                                          await ClipboardService.copyTextToClipboard(textToCopy);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('¡Información de dirección copiada al portapapeles!'),
                                                backgroundColor: AppColors.azulProfundo,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                                          foregroundColor: isDark ? AppColors.azulProfundo : Colors.white,
                                        ),
                                        icon: const Icon(Icons.copy, size: 18),
                                        label: const Text('Copy Info'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _direccionesList.length + 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
