import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ClipboardService {
  static const MethodChannel _channel = MethodChannel('com.soluro.app/clipboard');

  /// Copies an image file to the native clipboard.
  /// Falls back to share_plus if native clipboard copy fails or is unsupported.
  static Future<bool> copyImageToClipboard(String imagePath) async {
    if (imagePath.isEmpty) return false;

    final file = File(imagePath);
    if (!await file.exists()) return false;

    try {
      final bool success = await _channel.invokeMethod('copyImage', {
        'path': imagePath,
      });
      if (success) return true;
    } on PlatformException catch (e) {
      debugPrint('MethodChannel image copy error: ${e.message}');
    } catch (e) {
      debugPrint('Image copy error: $e');
    }

    // Fallback: Share the image using share_plus
    try {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Código QR Soluro',
      );
      return true;
    } catch (e) {
      debugPrint('Share fallback error: $e');
      return false;
    }
  }

  /// Copies formatted text to system clipboard
  static Future<void> copyTextToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
