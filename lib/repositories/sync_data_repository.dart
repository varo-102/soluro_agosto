import '../models/direccion_model.dart';
import '../models/qr_code_model.dart';
import 'data_repository.dart';
import 'local_data_repository.dart';

/// Implementación preparada para sincronización multi-usuario en la nube ('Cloud-Ready').
///
/// Esta clase encapsula el [LocalDataRepository] y provee la estructura para orquestar:
/// 1. Persistencia offline-first en la base de datos local.
/// 2. Sincronización en segundo plano con servicios cloud (Firebase Firestore, Supabase, API REST).
/// 3. Resolución de conflictos y actualización de campos [isSynced], [syncStatus] y [lastSyncedAt].
class SyncDataRepository implements DataRepository {
  final LocalDataRepository _localRepo;

  SyncDataRepository({LocalDataRepository? localRepo})
      : _localRepo = localRepo ?? LocalDataRepository();

  // --- MÉTODOS DE SINCRONIZACIÓN CLOUD ---

  /// Dispara un ciclo de sincronización bidireccional entre la base de datos local y la nube.
  Future<void> syncAll() async {
    // 1. Obtener registros locales pendientes de sincronización (isSynced == false)
    // 2. Subir o sincronizar con el backend de la nube (usando el userId autenticado)
    // 3. Descargar cambios remotos e insertarlos/actualizarlos localmente
    // 4. Actualizar lastSyncedAt e isSynced = true
  }

  /// Sincroniza códigos QR pendientes con la nube.
  Future<void> syncQRCodes() async {
    // TODO: Implementar llamada a API Cloud / WebSocket / Firebase / Supabase
  }

  /// Sincroniza direcciones pendientes con la nube.
  Future<void> syncDirecciones() async {
    // TODO: Implementar llamada a API Cloud / WebSocket / Firebase / Supabase
  }

  // --- DATA REPOSITORY CONTRACT IMPLEMENTATION ---

  @override
  Future<List<QRCodeModel>> getQRCodes({bool includeDeleted = false}) {
    return _localRepo.getQRCodes(includeDeleted: includeDeleted);
  }

  @override
  Future<QRCodeModel?> getQRCodeById(String id) {
    return _localRepo.getQRCodeById(id);
  }

  @override
  Future<void> saveQRCode(QRCodeModel qrCode) async {
    // Guarda localmente primero (Offline-First)
    await _localRepo.saveQRCode(qrCode);
    // Dispara sincronización asíncrona si hay conectividad
    // unawaited(syncQRCodes());
  }

  @override
  Future<void> deleteQRCode(String id) async {
    // Aplica borrado lógico localmente
    await _localRepo.deleteQRCode(id);
    // Notifica a la nube del borrado (registro con isDeleted = true)
    // unawaited(syncQRCodes());
  }

  @override
  Future<List<DireccionModel>> getDirecciones({bool includeDeleted = false}) {
    return _localRepo.getDirecciones(includeDeleted: includeDeleted);
  }

  @override
  Future<DireccionModel?> getDireccionById(String id) {
    return _localRepo.getDireccionById(id);
  }

  @override
  Future<void> saveDireccion(DireccionModel direccion) async {
    // Guarda localmente primero (Offline-First)
    await _localRepo.saveDireccion(direccion);
    // unawaited(syncDirecciones());
  }

  @override
  Future<void> deleteDireccion(String id) async {
    // Aplica borrado lógico localmente
    await _localRepo.deleteDireccion(id);
    // unawaited(syncDirecciones());
  }
}
