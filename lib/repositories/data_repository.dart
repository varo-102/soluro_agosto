import '../models/direccion_model.dart';
import '../models/qr_code_model.dart';

/// Interfaz abstracta del repositorio de datos para desacoplar
/// la lógica de almacenamiento de la interfaz de usuario.
abstract class DataRepository {
  // --- QR CODES ---

  /// Obtiene todos los códigos QR. Por defecto filtra los registros marcados como eliminados (`isDeleted == false`).
  Future<List<QRCodeModel>> getQRCodes({bool includeDeleted = false});

  /// Obtiene un código QR por su UUID.
  Future<QRCodeModel?> getQRCodeById(String id);

  /// Guarda o actualiza un código QR (creación si no existe, actualización si ya existe).
  Future<void> saveQRCode(QRCodeModel qrCode);

  /// Realiza un borrado lógico (Soft Delete) del código QR.
  Future<void> deleteQRCode(String id);

  // --- DIRECCIONES ---

  /// Obtiene todas las direcciones. Por defecto filtra las marcadas como eliminadas (`isDeleted == false`).
  Future<List<DireccionModel>> getDirecciones({bool includeDeleted = false});

  /// Obtiene una dirección por su UUID.
  Future<DireccionModel?> getDireccionById(String id);

  /// Guarda o actualiza una dirección (creación si no existe, actualización si ya existe).
  Future<void> saveDireccion(DireccionModel direccion);

  /// Realiza un borrado lógico (Soft Delete) de la dirección.
  Future<void> deleteDireccion(String id);
}
