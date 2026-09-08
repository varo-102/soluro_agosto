import 'package:uuid/uuid.dart';

class ArticuloCotizacionModel {
  final String id;
  final String cotizacionId;
  final String descripcion;
  final double precio;
  final double cantidad;

  ArticuloCotizacionModel({
    String? id,
    required this.cotizacionId,
    this.descripcion = '',
    this.precio = 0.0,
    this.cantidad = 0.0,
  }) : id = id ?? const Uuid().v4();

  double get subtotal => precio * cantidad;

  ArticuloCotizacionModel copyWith({
    String? id,
    String? cotizacionId,
    String? descripcion,
    double? precio,
    double? cantidad,
  }) {
    return ArticuloCotizacionModel(
      id: id ?? this.id,
      cotizacionId: cotizacionId ?? this.cotizacionId,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cotizacion_id': cotizacionId,
      'descripcion': descripcion,
      'precio': precio,
      'cantidad': cantidad,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory ArticuloCotizacionModel.fromJson(Map<String, dynamic> json) {
    return ArticuloCotizacionModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      cotizacionId: json['cotizacion_id']?.toString() ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory ArticuloCotizacionModel.fromMap(Map<String, dynamic> map) => ArticuloCotizacionModel.fromJson(map);
}
