import 'package:uuid/uuid.dart';

class ImagenCotizacionModel {
  final String id;
  final String cotizacionId;
  final String rutaLocal;

  ImagenCotizacionModel({
    String? id,
    required this.cotizacionId,
    required this.rutaLocal,
  }) : id = id ?? const Uuid().v4();

  ImagenCotizacionModel copyWith({
    String? id,
    String? cotizacionId,
    String? rutaLocal,
  }) {
    return ImagenCotizacionModel(
      id: id ?? this.id,
      cotizacionId: cotizacionId ?? this.cotizacionId,
      rutaLocal: rutaLocal ?? this.rutaLocal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cotizacion_id': cotizacionId,
      'ruta_local': rutaLocal,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory ImagenCotizacionModel.fromJson(Map<String, dynamic> json) {
    return ImagenCotizacionModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      cotizacionId: json['cotizacion_id']?.toString() ?? '',
      rutaLocal: json['ruta_local'] as String? ?? '',
    );
  }

  factory ImagenCotizacionModel.fromMap(Map<String, dynamic> map) => ImagenCotizacionModel.fromJson(map);
}
