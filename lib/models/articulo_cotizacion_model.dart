import 'dart:convert';
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cotizacion_id': cotizacionId,
      'descripcion': descripcion,
      'precio': precio,
      'cantidad': cantidad,
    };
  }

  factory ArticuloCotizacionModel.fromMap(Map<String, dynamic> map) {
    return ArticuloCotizacionModel(
      id: map['id'] ?? '',
      cotizacionId: map['cotizacion_id'] ?? '',
      descripcion: map['descripcion'] ?? '',
      precio: (map['precio'] ?? 0.0).toDouble(),
      cantidad: (map['cantidad'] ?? 0.0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ArticuloCotizacionModel.fromJson(String source) =>
      ArticuloCotizacionModel.fromMap(json.decode(source));
}
