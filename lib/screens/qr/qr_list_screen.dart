import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/qr_code_model.dart';
import '../../services/clipboard_service.dart';
import '../../services/database_helper.dart';
import '../../services/notification_service.dart';
import '../../services/quick_actions_service.dart';
import '../../theme/app_colors.dart';
import 'add_qr_modal.dart';
import 'full_screen_qr_viewer.dart';

class QRListScreen extends StatefulWidget {
  const QRListScreen({super.key});

  @override
  State<QRListScreen> createState() => QRListScreenState();
}

class QRListScreenState extends State<QRListScreen> {
  List<QRCodeModel> _qrList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadQRCodes();
  }

  Future<void> loadQRCodes() async {
    setState(() {
      _isLoading = true;
    });

    final list = await DatabaseHelper().getQRCodes();

    setState(() {
      _qrList = list;
      _isLoading = false;
    });

    // Register Quick Actions & check expiration notifications
    QuickActionsService().updateQuickActions(list);
    NotificationService().checkExpirationNotifications(list);
  }

  Future<void> _deleteQR(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar QR'),
        content: const Text('¿Estás seguro de que deseas eliminar este código QR?'),
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
      await DatabaseHelper().deleteQRCode(id);
      loadQRCodes();
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
      builder: (context) => AddQRModal(
        onQRSaved: loadQRCodes,
      ),
    );
  }

  void _showEditModal(QRCodeModel qr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddQRModal(
        qrToEdit: qr,
        onQRSaved: loadQRCodes,
      ),
    );
  }

  void openQRDetail(QRCodeModel qr) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenQRViewer(qrCode: qr),
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
      onRefresh: loadQRCodes,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _qrList.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 72,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes códigos QR guardados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Presiona "+ Añadir QR" para registrar tu primer cobro.',
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
                            label: const Text('Añadir QR'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _qrList.length) {
                          // Bottom "+ Añadir QR" button matching Stitch specs
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
                                'Añadir QR',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        final qr = _qrList[index];
                        final imageFile = File(qr.rutaImagen);
                        final hasImage = qr.rutaImagen.isNotEmpty && imageFile.existsSync();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () => openQRDetail(qr),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left Thumbnail
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: hasImage
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  imageFile,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.qr_code_2,
                                                color: AppColors.azulProfundo,
                                                size: 36,
                                              ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Bank Title & Reference
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              qr.banco,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              qr.referencia,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),

                                            // Expiration Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: qr.statusBackgroundColor,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    qr.daysRemaining < 3 ? Icons.warning : Icons.schedule,
                                                    size: 14,
                                                    color: qr.statusTextColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    qr.statusText,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: qr.statusTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                       // Edit & Delete Actions
                                       Row(
                                         mainAxisSize: MainAxisSize.min,
                                         children: [
                                           IconButton(
                                             icon: const Icon(Icons.edit_outlined, size: 22),
                                             color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                                             tooltip: 'Editar QR',
                                             onPressed: () => _showEditModal(qr),
                                           ),
                                           IconButton(
                                             icon: const Icon(Icons.delete_outline, size: 22),
                                             color: Colors.grey.shade600,
                                             tooltip: 'Eliminar QR',
                                             onPressed: () => _deleteQR(qr.id!),
                                           ),
                                         ],
                                       ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // [Copiar QR] Button
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (hasImage) {
                                        final copied = await ClipboardService.copyImageToClipboard(qr.rutaImagen);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                copied
                                                    ? '¡QR de ${qr.banco} copiado al portapapeles!'
                                                    : 'Se abrieron las opciones para compartir el QR',
                                              ),
                                              backgroundColor: AppColors.azulProfundo,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('No existe archivo de imagen para este QR')),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                                      foregroundColor: isDark ? AppColors.azulProfundo : Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Copiar QR'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _qrList.length + 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
