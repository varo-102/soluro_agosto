import 'package:uuid/uuid.dart';
import '../models/cotizacion_model.dart';
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

  // --- COTIZACIONES ---

  @override
  Future<List<CotizacionModel>> getCotizaciones({bool includeDeleted = false}) {
    return _dbHelper.getCotizaciones(includeDeleted: includeDeleted);
  }

  @override
  Future<CotizacionModel?> getCotizacionById(String id) {
    return _dbHelper.getCotizacionById(id);
  }

  @override
  Future<void> saveCotizacion(CotizacionModel cotizacion) async {
    final existing = await _dbHelper.getCotizacionById(cotizacion.id);
    if (existing != null) {
      final updated = cotizacion.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
        syncStatus: SyncStatus.pending,
      );
      await _dbHelper.updateCotizacion(updated);
    } else {
      await _dbHelper.insertCotizacion(cotizacion);
    }
  }

  @override
  Future<void> deleteCotizacion(String id) {
    return _dbHelper.softDeleteCotizacion(id);
  }

  @override
  Future<CotizacionModel> duplicateCotizacion(String id) async {
    final original = await _dbHelper.getCotizacionById(id);
    if (original == null) {
      throw Exception('No se encontró la cotización a duplicar con ID: $id');
    }

    final newId = const Uuid().v4();
    final now = DateTime.now();

    final duplicatedArticles = original.articulos.map((art) {
      return CotizacionArticuloModel(
        id: const Uuid().v4(),
        cotizacionId: newId,
        orden: art.orden,
        descripcion: art.descripcion,
        precio: art.precio,
        cantidad: art.cantidad,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    final nextNumber = await _dbHelper.getNextCotizacionNumero();

    final duplicated = CotizacionModel(
      id: newId,
      userId: original.userId,
      numero: nextNumber,
      titulo: '${original.titulo} (copia)',
      notas: original.notas,
      articulos: duplicatedArticles,
      fotos: List.from(original.fotos),
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      syncStatus: SyncStatus.pending,
      isDeleted: false,
    );

    await _dbHelper.insertCotizacion(duplicated);
    return duplicated;
  }

  @override
  Future<int> getNextCotizacionNumero() {
    return _dbHelper.getNextCotizacionNumero();
  }
}
