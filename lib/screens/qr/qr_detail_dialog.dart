import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/qr_code_model.dart';
import '../../services/clipboard_service.dart';
import '../../theme/app_colors.dart';

class QRDetailDialog extends StatelessWidget {
  final QRCodeModel qrCode;

  const QRDetailDialog({super.key, required this.qrCode});

  @override
  Widget build(BuildContext context) {
    final imageFile = File(qrCode.rutaImagen);
    final hasFile = qrCode.rutaImagen.isNotEmpty && imageFile.existsSync();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    qrCode.banco,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulProfundo,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              qrCode.referencia,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),

            // Expiration Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: qrCode.statusBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    qrCode.daysRemaining < 3 ? Icons.warning : Icons.schedule,
                    size: 16,
                    color: qrCode.statusTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    qrCode.statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: qrCode.statusTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Large Image Display
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: hasFile
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 80, color: AppColors.azulProfundo),
                          SizedBox(height: 8),
                          Text('Imagen QR no encontrada localmente'),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Copiar QR Button
            ElevatedButton.icon(
              onPressed: () async {
                if (hasFile) {
                  final copied = await ClipboardService.copyImageToClipboard(qrCode.rutaImagen);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          copied
                              ? '¡Imagen QR copiada al portapapeles!'
                              : 'Se inició la acción de compartir QR',
                        ),
                        backgroundColor: AppColors.azulProfundo,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No hay archivo de imagen para copiar')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulProfundo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.copy),
              label: const Text('Copiar QR'),
            ),
          ],
        ),
      ),
    );
  }
}
