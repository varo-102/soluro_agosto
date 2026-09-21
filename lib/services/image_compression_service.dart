import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Servicio encargado de la selección, compresión y almacenamiento de fotografías
/// para las cotizaciones de Soluro.
class ImageCompressionService {
  static final ImageCompressionService _instance =
      ImageCompressionService._internal();

  final ImagePicker _picker = ImagePicker();

  factory ImageCompressionService() => _instance;

  ImageCompressionService._internal();

  /// Permite al usuario capturar una foto con la cámara o elegirla de la galería,
  /// comprime la imagen según los requerimientos estrictos y la guarda localmente.
  ///
  /// Requerimientos:
  /// - Usar `flutter_image_compress`.
  /// - Redimensionar lado más largo a 800px.
  /// - Convertir a JPEG (sin transparencia).
  /// - Calidad 70%.
  Future<String?> pickAndCompressImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
      );

      if (pickedFile == null) return null;

      return await compressAndSaveImage(pickedFile.path);
    } catch (e) {
      debugPrint('Error seleccionando imagen: $e');
      return null;
    }
  }

  /// Comprime una imagen existente en [sourcePath] aplicando los parámetros:
  /// - Lado más largo a 800px.
  /// - JPEG sin transparencia.
  /// - Calidad 70%.
  Future<String?> compressAndSaveImage(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'cotizaciones_fotos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileName = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = p.join(photosDir.path, fileName);

      // Intentar primero con flutter_image_compress (enfoque principal móvil)
      try {
        final XFile? result = await FlutterImageCompress.compressAndGetFile(
          sourcePath,
          targetPath,
          minWidth: 800,
          minHeight: 800,
          quality: 70,
          format: CompressFormat.jpeg,
          keepExif: false,
        );

        if (result != null) {
          return result.path;
        }
      } catch (nativeError) {
        debugPrint(
            'flutter_image_compress no disponible en esta plataforma ($nativeError). Aplicando compresión alternativa con paquete image...');
      }

      // Fallback multiplataforma (ej. Windows Desktop durante desarrollo)
      return await _compressWithImagePackage(sourcePath, targetPath);
    } catch (e) {
      debugPrint('Error en compressAndSaveImage: $e');
      return null;
    }
  }

  /// Compresión pura en Dart con paquete `image` como respaldo multiplataforma
  Future<String?> _compressWithImagePackage(
      String sourcePath, String targetPath) async {
    final fileBytes = await File(sourcePath).readAsBytes();
    final image = img.decodeImage(fileBytes);
    if (image == null) return null;

    // Redimensionar para que el lado más largo sea máximo 800px
    int targetWidth = image.width;
    int targetHeight = image.height;

    if (image.width > image.height) {
      if (image.width > 800) {
        targetWidth = 800;
        targetHeight = (image.height * (800 / image.width)).round();
      }
    } else {
      if (image.height > 800) {
        targetHeight = 800;
        targetWidth = (image.width * (800 / image.height)).round();
      }
    }

    final resized = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    // Codificar a JPEG con calidad 70%
    final jpgBytes = img.encodeJpg(resized, quality: 70);
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(jpgBytes);

    return targetPath;
  }
}
