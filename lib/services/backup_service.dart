import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';

/// Metadatos contenidos en el archivo de respaldo para validación e inspección previa
class BackupMetadata {
  final String appName;
  final String formatVersion;
  final DateTime createdAt;
  final int qrCount;
  final int direccionesCount;
  final int cotizacionesCount;
  final int mediaFilesCount;

  BackupMetadata({
    required this.appName,
    required this.formatVersion,
    required this.createdAt,
    required this.qrCount,
    required this.direccionesCount,
    required this.cotizacionesCount,
    required this.mediaFilesCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'formatVersion': formatVersion,
      'createdAt': createdAt.toIso8601String(),
      'qrCount': qrCount,
      'direccionesCount': direccionesCount,
      'cotizacionesCount': cotizacionesCount,
      'mediaFilesCount': mediaFilesCount,
    };
  }

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      appName: map['appName'] as String? ?? 'Soluro',
      formatVersion: map['formatVersion'] as String? ?? '1.0.0',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      qrCount: (map['qrCount'] as num?)?.toInt() ?? 0,
      direccionesCount: (map['direccionesCount'] as num?)?.toInt() ?? 0,
      cotizacionesCount: (map['cotizacionesCount'] as num?)?.toInt() ?? 0,
      mediaFilesCount: (map['mediaFilesCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  int get totalRecords => qrCount + direccionesCount + cotizacionesCount;
}

/// Resultado de una operación de exportación
class BackupExportResult {
  final File backupFile;
  final BackupMetadata metadata;
  final int fileSizeBytes;

  BackupExportResult({
    required this.backupFile,
    required this.metadata,
    required this.fileSizeBytes,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Servicio centralizado de Respaldo y Restauración (Backup & Restore)
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String markerFileName = 'soluro_first_launch_done.flag';

  /// Genera un archivo empaquetado (.soluro) que contiene:
  /// 1. La base de datos SQLite consolidada (soluro_database.db)
  /// 2. Las fotos de cotizaciones y códigos QR
  /// 3. manifest.json con metadatos de integridad
  Future<BackupExportResult> createBackup() async {
    // 1. Forzar volcado de transacciones WAL
    await _dbHelper.checkpointWal();

    // 2. Obtener estadísticas de la base de datos
    final stats = await _dbHelper.getDatabaseStats();

    // 3. Localizar archivos de datos
    final dbPath = await _dbHelper.getDatabaseFilePath();
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('El archivo de base de datos no fue encontrado.');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final qrDir = Directory(p.join(appDocDir.path, 'qr_images'));
    final fotosDir = Directory(p.join(appDocDir.path, 'cotizaciones_fotos'));

    final List<File> mediaFiles = [];
    if (await qrDir.exists()) {
      final list = qrDir.listSync().whereType<File>();
      mediaFiles.addAll(list);
    }
    if (await fotosDir.exists()) {
      final list = fotosDir.listSync().whereType<File>();
      mediaFiles.addAll(list);
    }

    final metadata = BackupMetadata(
      appName: 'Soluro',
      formatVersion: '1.0.0',
      createdAt: DateTime.now(),
      qrCount: stats['qr_codes'] ?? 0,
      direccionesCount: stats['direcciones'] ?? 0,
      cotizacionesCount: stats['cotizaciones'] ?? 0,
      mediaFilesCount: mediaFiles.length,
    );

    // 4. Crear el archivo ZIP comprimido (.soluro)
    final archive = Archive();

    // Agregar manifest.json
    final manifestBytes = utf8.encode(jsonEncode(metadata.toMap()));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // Agregar base de datos SQLite
    final dbBytes = await dbFile.readAsBytes();
    archive.addFile(ArchiveFile('database/soluro_database.db', dbBytes.length, dbBytes));

    // Agregar archivos multimedia (QR fotos y fotos de cotizaciones)
    for (final file in mediaFiles) {
      final relativePath = p.relative(file.path, from: appDocDir.path);
      // Usar separadores normalizados Unix para compatibilidad en el zip
      final archivePath = p.posix.joinAll(p.split(relativePath));
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile('files/$archivePath', bytes.length, bytes));
    }

    final zipEncoder = ZipEncoder();
    final encodedData = zipEncoder.encode(archive);

    // 5. Guardar en directorio temporal de caché con nombre descriptivo
    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(metadata.createdAt);
    final backupFileName = 'soluro_backup_$dateStr.soluro';
    final backupFilePath = p.join(tempDir.path, backupFileName);
    final backupFile = File(backupFilePath);
    await backupFile.writeAsBytes(encodedData, flush: true);

    return BackupExportResult(
      backupFile: backupFile,
      metadata: metadata,
      fileSizeBytes: encodedData.length,
    );
  }

  /// Comparte el archivo de respaldo a través de share_plus (Google Drive, WhatsApp, Correo, etc.)
  Future<void> shareBackup(File backupFile, BackupMetadata metadata) async {
    final xFile = XFile(backupFile.path, name: p.basename(backupFile.path), mimeType: 'application/octet-stream');
    await Share.shareXFiles(
      [xFile],
      text: 'Copia de seguridad Soluro - ${metadata.formattedDate}',
      subject: 'Respaldo Soluro',
    );
  }

  /// Guarda la copia de seguridad solicitando al usuario la ubicación (vía FilePicker)
  Future<String?> saveBackupToUserStorage(File backupFile) async {
    try {
      final bytes = await backupFile.readAsBytes();
      final String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar copia de seguridad Soluro',
        fileName: p.basename(backupFile.path),
        type: FileType.custom,
        allowedExtensions: ['soluro', 'zip'],
        bytes: bytes,
      );

      if (selectedPath != null) {
        // En algunas plataformas móviles saveFile escribe automáticamente los bytes pasados;
        // en otras devuelve la ruta seleccionada. Verificamos y escribimos si no existe.
        final targetFile = File(selectedPath);
        if (!await targetFile.exists() || await targetFile.length() == 0) {
          await targetFile.writeAsBytes(bytes, flush: true);
        }
        return selectedPath;
      }
      return null;
    } catch (e) {
      debugPrint('Error guardando en almacenamiento: $e');
      rethrow;
    }
  }

  /// Lee e inspecciona un archivo de respaldo antes de restaurarlo
  Future<BackupMetadata> inspectBackupFile(File file) async {
    final bytes = await file.readAsBytes();
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes);

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile != null) {
      final content = utf8.decode(manifestFile.content as List<int>);
      final map = jsonDecode(content) as Map<String, dynamic>;
      return BackupMetadata.fromMap(map);
    }

    // Si no contiene manifest.json, comprobar si al menos contiene soluro_database.db
    final dbFile = archive.findFile('database/soluro_database.db') ??
        archive.findFile('soluro_database.db');
    if (dbFile != null) {
      return BackupMetadata(
        appName: 'Soluro (Archivo Legado)',
        formatVersion: '0.9',
        createdAt: file.lastModifiedSync(),
        qrCount: 0,
        direccionesCount: 0,
        cotizacionesCount: 0,
        mediaFilesCount: 0,
      );
    }

    throw Exception('El archivo seleccionado no es una copia de seguridad válida de Soluro.');
  }

  /// Restaura los datos del archivo de respaldo seleccionado:
  /// - Cierra la base de datos actual de forma limpia
  /// - Sobrescribe la base de datos soluro_database.db
  /// - Extrae y coloca las fotos de QR y cotizaciones
  /// - Reabre la conexión de base de datos
  Future<BackupMetadata> restoreBackup(File file) async {
    final bytes = await file.readAsBytes();
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes);

    // 1. Obtener y validar manifest
    BackupMetadata metadata;
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile != null) {
      final content = utf8.decode(manifestFile.content as List<int>);
      metadata = BackupMetadata.fromMap(jsonDecode(content) as Map<String, dynamic>);
    } else {
      metadata = BackupMetadata(
        appName: 'Soluro',
        formatVersion: '1.0.0',
        createdAt: DateTime.now(),
        qrCount: 0,
        direccionesCount: 0,
        cotizacionesCount: 0,
        mediaFilesCount: 0,
      );
    }

    // 2. Extraer archivo de base de datos
    final dbEntry = archive.findFile('database/soluro_database.db') ??
        archive.findFile('soluro_database.db');
    if (dbEntry == null) {
      throw Exception('El archivo de respaldo no contiene la base de datos principal.');
    }

    // 3. Cerrar conexión SQLite activa
    await _dbHelper.closeDatabase();

    // 4. Escribir base de datos restaurada
    final targetDbPath = await _dbHelper.getDatabaseFilePath();
    final targetDbFile = File(targetDbPath);

    // Eliminar posibles archivos residuales de WAL o SHM previos
    final walFile = File('$targetDbPath-wal');
    final shmFile = File('$targetDbPath-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    await targetDbFile.writeAsBytes(dbEntry.content as List<int>, flush: true);

    // 5. Extraer archivos multimedia asociados
    final appDocDir = await getApplicationDocumentsDirectory();
    for (final archiveFile in archive) {
      if (!archiveFile.isFile) continue;
      final name = archiveFile.name;

      if (name.startsWith('files/')) {
        final relative = name.substring('files/'.length);
        final destinationPath = p.join(appDocDir.path, relative);
        final destFile = File(destinationPath);
        await destFile.parent.create(recursive: true);
        await destFile.writeAsBytes(archiveFile.content as List<int>, flush: true);
      }
    }

    // 6. Reabrir conexión SQLite
    await _dbHelper.reopenDatabase();

    // 7. Marcar el asistente inicial como completado
    await markFirstLaunchCompleted();

    return metadata;
  }

  /// Comprueba si la aplicación se está ejecutando por primera vez tras una instalación
  /// y busca copias de seguridad existentes detectables en el almacenamiento del dispositivo.
  Future<FirstLaunchCheckResult> checkFirstLaunchAndLookForBackups() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final markerFile = File(p.join(appDocDir.path, markerFileName));

    if (await markerFile.exists()) {
      return FirstLaunchCheckResult(isFirstLaunch: false, detectedBackups: []);
    }

    // Buscar copias de seguridad en directorios habituales accesibles
    final List<File> detected = [];
    try {
      final searchDirs = <Directory>[];

      // Directorio de descargas
      final downloadsDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (downloadsDirs != null) {
        searchDirs.addAll(downloadsDirs);
      }

      // Directorio general de documentos externos
      final docDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
      if (docDirs != null) {
        searchDirs.addAll(docDirs);
      }

      // Si es Android estándar, agregar la carpeta pública Download si es accesible
      if (!kIsWeb && Platform.isAndroid) {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          searchDirs.add(publicDownload);
        }
      }

      for (final dir in searchDirs) {
        if (!await dir.exists()) continue;
        try {
          final entities = dir.listSync();
          for (final entity in entities) {
            if (entity is File) {
              final name = p.basename(entity.path).toLowerCase();
              if (name.endsWith('.soluro') || (name.contains('soluro') && name.endsWith('.zip'))) {
                detected.add(entity);
              }
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Aviso buscando copias de seguridad: $e');
    }

    // Ordenar detectadas por fecha más reciente
    detected.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return FirstLaunchCheckResult(
      isFirstLaunch: true,
      detectedBackups: detected,
    );
  }

  /// Marca que el asistente o comprobación de bienvenida/restauración ya fue atendido
  Future<void> markFirstLaunchCompleted() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final markerFile = File(p.join(appDocDir.path, markerFileName));
      await markerFile.writeAsString(DateTime.now().toIso8601String(), flush: true);
    } catch (e) {
      debugPrint('Error guardando flag de primer inicio: $e');
    }
  }
}

/// Estado de la comprobación al iniciar la aplicación
class FirstLaunchCheckResult {
  final bool isFirstLaunch;
  final List<File> detectedBackups;

  FirstLaunchCheckResult({
    required this.isFirstLaunch,
    required this.detectedBackups,
  });

  bool get hasDetectedBackups => detectedBackups.isNotEmpty;
}
