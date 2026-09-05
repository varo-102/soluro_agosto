import 'package:flutter_test/flutter_test.dart';
import 'package:soluro/models/direccion_model.dart';
import 'package:soluro/models/qr_code_model.dart';
import 'package:soluro/models/sync_status.dart';
import 'package:soluro/repositories/data_repository.dart';
import 'package:soluro/repositories/local_data_repository.dart';
import 'package:soluro/repositories/sync_data_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soluro/services/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Cloud-Ready Model Tests', () {
    test('QRCodeModel assigns valid UUID v4 and default sync metadata', () {
      final qr = QRCodeModel(
        banco: 'Banco Sol',
        referencia: 'Pago Mensual',
        fechaExpiracion: DateTime.now().add(const Duration(days: 10)),
        rutaImagen: '/test/path.png',
      );

      // UUID v4 format check (8-4-4-4-12 hex)
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(qr.id), isTrue);
      expect(qr.userId, isNull);
      expect(qr.isSynced, isFalse);
      expect(qr.syncStatus, equals(SyncStatus.pending));
      expect(qr.lastSyncedAt, isNull);
      expect(qr.isDeleted, isFalse);
      expect(qr.createdAt, isA<DateTime>());
      expect(qr.updatedAt, isA<DateTime>());
    });

    test('DireccionModel assigns valid UUID v4 and default sync metadata', () {
      final dir = DireccionModel(
        titulo: 'Almacén Central',
        detalle: 'Av. Costanera 100',
        urlMaps: 'https://maps.google.com/?q=0,0',
      );

      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(dir.id), isTrue);
      expect(dir.userId, isNull);
      expect(dir.isSynced, isFalse);
      expect(dir.syncStatus, equals(SyncStatus.pending));
      expect(dir.lastSyncedAt, isNull);
      expect(dir.isDeleted, isFalse);
      expect(dir.createdAt, isA<DateTime>());
      expect(dir.updatedAt, isA<DateTime>());
    });

    test('Standard JSON Serialization with ISO-8601 formatting for QRCodeModel', () {
      final now = DateTime.now();
      final qr = QRCodeModel(
        banco: 'BNB',
        referencia: 'Factura 456',
        fechaExpiracion: now.add(const Duration(days: 5)),
        rutaImagen: '/path/to/qr.png',
      );

      final json = qr.toJson();
      expect(json['id'], equals(qr.id));
      expect(json['banco'], equals('BNB'));
      expect(json['referencia'], equals('Factura 456'));
      expect(json['fecha_expiracion'], equals(qr.fechaExpiracion.toIso8601String()));
      expect(json['created_at'], equals(qr.createdAt.toIso8601String()));
      expect(json['updated_at'], equals(qr.updatedAt.toIso8601String()));
      expect(json['is_synced'], equals(0));
      expect(json['sync_status'], equals('pending'));
      expect(json['is_deleted'], equals(0));

      final restored = QRCodeModel.fromJson(json);
      expect(restored.id, equals(qr.id));
      expect(restored.banco, equals(qr.banco));
      expect(restored.referencia, equals(qr.referencia));
      expect(restored.isSynced, isFalse);
      expect(restored.syncStatus, equals(SyncStatus.pending));
      expect(restored.isDeleted, isFalse);
    });

    test('Standard JSON Serialization with ISO-8601 formatting for DireccionModel', () {
      final dir = DireccionModel(
        titulo: 'Sucursal Sur',
        detalle: 'Calle 21 de Calacoto',
        urlMaps: 'https://maps.google.com/?q=-16.54,-68.08',
      );

      final json = dir.toJson();
      expect(json['id'], equals(dir.id));
      expect(json['titulo'], equals('Sucursal Sur'));
      expect(json['detalle'], equals('Calle 21 de Calacoto'));
      expect(json['url_maps'], equals('https://maps.google.com/?q=-16.54,-68.08'));
      expect(json['created_at'], equals(dir.createdAt.toIso8601String()));
      expect(json['updated_at'], equals(dir.updatedAt.toIso8601String()));
      expect(json['is_deleted'], equals(0));

      final restored = DireccionModel.fromJson(json);
      expect(restored.id, equals(dir.id));
      expect(restored.titulo, equals(dir.titulo));
      expect(restored.detalle, equals(dir.detalle));
      expect(restored.isDeleted, isFalse);
    });

    test('Existing business logic preserved (expiration badges and formattedCopyText)', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final qr = QRCodeModel(
        banco: 'Banco BISA',
        referencia: 'Cuenta #123',
        fechaExpiracion: futureDate,
        rutaImagen: '/path/to/img.png',
      );

      expect(qr.daysRemaining, greaterThanOrEqualTo(9));
      expect(qr.statusText, contains('Expira en'));

      final dir = DireccionModel(
        titulo: 'Downtown Hub',
        detalle: '123 Market Street, Suite 400',
        urlMaps: 'https://maps.google.com/?q=123+Market',
      );

      expect(
        dir.formattedCopyText,
        equals('Downtown Hub\n123 Market Street, Suite 400\nhttps://maps.google.com/?q=123+Market'),
      );
    });
  });

  group('Repository & Soft Delete Tests', () {
    late DataRepository repository;

    setUp(() {
      repository = LocalDataRepository();
    });

    test('Soft delete updates isDeleted flag and filters in UI queries', () async {
      final qr = QRCodeModel(
        banco: 'Banco Mercantil',
        referencia: 'Cobro Especial',
        fechaExpiracion: DateTime.now().add(const Duration(days: 20)),
        rutaImagen: '',
      );

      await repository.saveQRCode(qr);

      // Verify it exists in UI query
      final activeQRsBefore = await repository.getQRCodes();
      expect(activeQRsBefore.any((item) => item.id == qr.id), isTrue);

      // Soft delete
      await repository.deleteQRCode(qr.id);

      // Verify UI query (includeDeleted = false) does NOT return the deleted QR
      final activeQRsAfter = await repository.getQRCodes();
      expect(activeQRsAfter.any((item) => item.id == qr.id), isFalse);

      // Verify it is still stored locally with isDeleted == true
      final allQRs = await repository.getQRCodes(includeDeleted: true);
      final deletedQr = allQRs.firstWhere((item) => item.id == qr.id);
      expect(deletedQr.isDeleted, isTrue);
      expect(deletedQr.syncStatus, equals(SyncStatus.pending));

      // Cleanup
      await DatabaseHelper().hardDeleteQRCode(qr.id);
    });

    test('DireccionModel soft delete behaves correctly', () async {
      final dir = DireccionModel(
        titulo: 'Oficina Temporal',
        detalle: 'Piso 3',
        urlMaps: 'https://maps.google.com',
      );

      await repository.saveDireccion(dir);

      final activeDirsBefore = await repository.getDirecciones();
      expect(activeDirsBefore.any((item) => item.id == dir.id), isTrue);

      await repository.deleteDireccion(dir.id);

      final activeDirsAfter = await repository.getDirecciones();
      expect(activeDirsAfter.any((item) => item.id == dir.id), isFalse);

      final allDirs = await repository.getDirecciones(includeDeleted: true);
      final deletedDir = allDirs.firstWhere((item) => item.id == dir.id);
      expect(deletedDir.isDeleted, isTrue);

      // Cleanup
      await DatabaseHelper().hardDeleteDireccion(dir.id);
    });

    test('SyncDataRepository implements DataRepository contract and delegates correctly', () async {
      final syncRepo = SyncDataRepository();
      expect(syncRepo, isA<DataRepository>());
    });
  });
}
