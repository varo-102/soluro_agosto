import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<String> _getAppDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final soluroDir = Directory(path.join(dir.path, 'soluro', 'cotizaciones'));
    if (!await soluroDir.exists()) {
      await soluroDir.create(recursive: true);
    }
    return soluroDir.path;
  }

  Future<String> _getCotizacionDir(String cotizacionId) async {
    final baseDir = await _getAppDir();
    final dir = Directory(path.join(baseDir, cotizacionId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<String?> pickAndCompressImage(String cotizacionId, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null;

      final cotizacionDir = await _getCotizacionDir(cotizacionId);
      final fileName = '${const Uuid().v4()}.jpg';
      final targetPath = path.join(cotizacionDir, fileName);

      // Compress and save
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        return compressedFile.path;
      }
      return null;
    } catch (e) {
      print('Error picking/compressing image: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteCotizacionFolder(String cotizacionId) async {
    try {
      final dirPath = await _getCotizacionDir(cotizacionId);
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting folder: $e');
    }
  }

  Future<List<String>> duplicateCotizacionImages(String oldCotizacionId, String newCotizacionId) async {
    List<String> newPaths = [];
    try {
      final oldDir = Directory(await _getCotizacionDir(oldCotizacionId));
      if (!await oldDir.exists()) return newPaths;

      final newDir = Directory(await _getCotizacionDir(newCotizacionId));

      final files = oldDir.listSync();
      for (var entity in files) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          final newPath = path.join(newDir.path, fileName);
          await entity.copy(newPath);
          newPaths.add(newPath);
        }
      }
    } catch (e) {
      print('Error duplicating images: $e');
    }
    return newPaths;
  }
}
