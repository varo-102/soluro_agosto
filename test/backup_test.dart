// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:soluro/services/backup_service.dart';
import 'package:soluro/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  final Directory appDocDir;

  FakePathProviderPlatform({required this.tempDir, required this.appDocDir});

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => appDocDir.path;

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async =>
      [tempDir.path];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late Directory appDocDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('soluro_test_temp_');
    appDocDir = await Directory.systemTemp.createTemp('soluro_test_doc_');
    PathProviderPlatform.instance = FakePathProviderPlatform(
      tempDir: tempDir,
      appDocDir: appDocDir,
    );
  });

  tearDown(() async {
    await DatabaseHelper().closeDatabase();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    if (await appDocDir.exists()) await appDocDir.delete(recursive: true);
  });

  group('BackupMetadata & Serialization Tests', () {
    test('BackupMetadata converts to and from map accurately', () {
      final now = DateTime.now();
      final meta = BackupMetadata(
        appName: 'Soluro',
        formatVersion: '1.0.0',
        createdAt: now,
        qrCount: 5,
        direccionesCount: 3,
        cotizacionesCount: 12,
        mediaFilesCount: 7,
      );

      expect(meta.totalRecords, equals(20));
      expect(meta.formattedDate, isNotEmpty);

      final map = meta.toMap();
      final reconstructed = BackupMetadata.fromMap(map);

      expect(reconstructed.appName, equals('Soluro'));
      expect(reconstructed.formatVersion, equals('1.0.0'));
      expect(reconstructed.qrCount, equals(5));
      expect(reconstructed.direccionesCount, equals(3));
      expect(reconstructed.cotizacionesCount, equals(12));
      expect(reconstructed.mediaFilesCount, equals(7));
      expect(reconstructed.totalRecords, equals(20));
    });
  });

  group('BackupService Creation & Inspection Tests', () {
    test('createBackup produces a valid .soluro archive and inspectBackup reads it', () async {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      expect(db.isOpen, isTrue);

      final backupService = BackupService();
      final result = await backupService.createBackup();

      expect(result.backupFile.existsSync(), isTrue);
      expect(result.fileSizeBytes, greaterThan(0));
      expect(result.backupFile.path.endsWith('.soluro'), isTrue);

      // Inspeccionar archivo
      final inspectedMeta = await backupService.inspectBackupFile(result.backupFile);
      expect(inspectedMeta.appName, equals('Soluro'));
      expect(inspectedMeta.qrCount, greaterThanOrEqualTo(0));
      expect(inspectedMeta.direccionesCount, greaterThanOrEqualTo(0));
    });

    test('restoreBackup completes and reopens the database cleanly', () async {
      final dbHelper = DatabaseHelper();
      await dbHelper.database;

      final backupService = BackupService();
      final result = await backupService.createBackup();

      // Restaurar desde el archivo generado
      final restoredMeta = await backupService.restoreBackup(result.backupFile);
      expect(restoredMeta.appName, equals('Soluro'));

      // Verificar que la base de datos se puede volver a consultar inmediatamente
      final reloadedDb = await dbHelper.database;
      expect(reloadedDb.isOpen, isTrue);
      final stats = await dbHelper.getDatabaseStats();
      expect(stats.containsKey('qr_codes'), isTrue);
    });
  });
}
