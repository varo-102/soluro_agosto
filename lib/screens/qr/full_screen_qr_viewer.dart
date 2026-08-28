import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/qr_code_model.dart';
import '../../services/clipboard_service.dart';
import '../../theme/app_colors.dart';

class FullScreenQRViewer extends StatefulWidget {
  final QRCodeModel qrCode;

  const FullScreenQRViewer({super.key, required this.qrCode});

  @override
  State<FullScreenQRViewer> createState() => _FullScreenQRViewerState();
}

class _FullScreenQRViewerState extends State<FullScreenQRViewer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.qrCode.rutaImagen);
    final hasFile = widget.qrCode.rutaImagen.isNotEmpty && imageFile.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Fullscreen Image with Pinch-to-Zoom
            GestureDetector(
              onTap: _toggleControls,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: hasFile
                          ? Image.file(
                              imageFile,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.qr_code_2,
                                  size: 160,
                                  color: AppColors.amarilloSol,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.qrCode.banco,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.qrCode.referencia,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Top Overlay Bar (Close Button, Bank Name & Reference)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.qrCode.banco,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.qrCode.referencia.isNotEmpty)
                              Text(
                                widget.qrCode.referencia,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppColors.amarilloSol, size: 24),
                        tooltip: 'Copiar QR',
                        onPressed: () async {
                          if (hasFile) {
                            final copied = await ClipboardService.copyImageToClipboard(
                              widget.qrCode.rutaImagen,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    copied
                                        ? '¡QR copiado al portapapeles!'
                                        : 'Se inició compartir QR',
                                  ),
                                  backgroundColor: AppColors.azulProfundo,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
