import 'data_repository.dart';
import 'local_data_repository.dart';

/// Proveedor centralizado para la instancia activa de [DataRepository].
///
/// Permite intercambiar [LocalDataRepository] por [SyncDataRepository]
/// o por implementaciones de prueba sin modificar los widgets de la interfaz de usuario.
class RepositoryProvider {
  /// Instancia activa del repositorio de datos (por defecto [LocalDataRepository]).
  static DataRepository instance = LocalDataRepository();
}
