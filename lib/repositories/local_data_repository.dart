import '../models/direccion_model.dart';
import '../models/qr_code_model.dart';
import '../models/sync_status.dart';
import '../services/database_helper.dart';
import 'data_repository.dart';

/// Implementación local del repositorio respaldada por SQLite mediante [DatabaseHelper].
class LocalDataRepository implements DataRepository {
  final DatabaseHelper _dbHelper;

  LocalDataRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // --- QR CODES ---

  @override
  Future<List<QRCodeModel>> getQRCodes({bool includeDeleted = false}) {
    return _dbHelper.getQRCodes(includeDeleted: includeDeleted);
  }

  @override
  Future<QRCodeModel?> getQRCodeById(String id) {
    return _dbHelper.getQRCodeById(id);
  }

  @override
  Future<void> saveQRCode(QRCodeModel qrCode) async {
    final existing = await _dbHelper.getQRCodeById(qrCode.id);
    if (existing != null) {
      final updated = qrCode.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
        syncStatus: SyncStatus.pending,
      );
      await _dbHelper.updateQRCode(updated);
    } else {
      await _dbHelper.insertQRCode(qrCode);
    }
  }

  @override
  Future<void> deleteQRCode(String id) {
    return _dbHelper.softDeleteQRCode(id);
  }

  // --- DIRECCIONES ---

  @override
  Future<List<DireccionModel>> getDirecciones({bool includeDeleted = false}) {
    return _dbHelper.getDirecciones(includeDeleted: includeDeleted);
  }

  @override
  Future<DireccionModel?> getDireccionById(String id) {
    return _dbHelper.getDireccionById(id);
  }

  @override
  Future<void> saveDireccion(DireccionModel direccion) async {
    final existing = await _dbHelper.getDireccionById(direccion.id);
    if (existing != null) {
      final updated = direccion.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
        syncStatus: SyncStatus.pending,
      );
      await _dbHelper.updateDireccion(updated);
    } else {
      await _dbHelper.insertDireccion(direccion);
    }
  }

  @override
  Future<void> deleteDireccion(String id) {
    return _dbHelper.softDeleteDireccion(id);
  }
}
