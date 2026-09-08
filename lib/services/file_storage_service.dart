import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();

  factory FileStorageService() => _instance;

  FileStorageService._internal();

  Future<Directory> _getCotizacionesDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final cotizacionesDir = Directory(path.join(docsDir.path, 'cotizaciones'));
    if (!await cotizacionesDir.exists()) {
      await cotizacionesDir.create(recursive: true);
    }
    return cotizacionesDir;
  }

  Future<Directory> _getCotizacionDir(String cotizacionId) async {
    final baseDir = await _getCotizacionesDir();
    final dir = Directory(path.join(baseDir.path, cotizacionId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Comprime y guarda la imagen en la carpeta de la cotización.
  /// Redimensiona a 800px máximo, JPEG, calidad 70%.
  Future<String?> saveCotizacionImage(String cotizacionId, String tempImagePath) async {
    try {
      final cotizacionDir = await _getCotizacionDir(cotizacionId);
      final uuidFoto = const Uuid().v4();
      final targetPath = path.join(cotizacionDir.path, '$uuidFoto.jpg');

      // flutter_image_compress maneja la preservación del aspect ratio 
      // y usa minWidth/minHeight como límites máximos en la práctica si la imagen es muy grande.
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        tempImagePath,
        targetPath,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        return compressedFile.path;
      } else {
        // En plataformas no soportadas o si falla, podríamos hacer copia directa
        final File tempFile = File(tempImagePath);
        final File newFile = await tempFile.copy(targetPath);
        return newFile.path;
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  /// Borra físicamente la carpeta entera de la cotización
  Future<void> deleteCotizacionDirectory(String cotizacionId) async {
    try {
      final baseDir = await _getCotizacionesDir();
      final dir = Directory(path.join(baseDir.path, cotizacionId));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting directory: $e');
    }
  }

  /// Duplica físicamente las imágenes a la carpeta de la nueva cotización (copia)
  Future<void> duplicateCotizacionDirectory(String oldId, String newId) async {
    try {
      final baseDir = await _getCotizacionesDir();
      final oldDir = Directory(path.join(baseDir.path, oldId));
      final newDir = await _getCotizacionDir(newId);

      if (await oldDir.exists()) {
        final entities = await oldDir.list().toList();
        for (var entity in entities) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            final newFilePath = path.join(newDir.path, fileName);
            await entity.copy(newFilePath);
          }
        }
      }
    } catch (e) {
      debugPrint('Error duplicating directory: $e');
    }
  }

  /// Lee una imagen como bytes, ideal para incrustar en PDF
  Future<List<int>?> readImageAsBytes(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error reading image: $e');
    }
    return null;
  }
}
