import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'articulo_cotizacion_model.dart';
import 'sync_status.dart';

class CotizacionModel {
  final String id;
  final String? userId;
  final String titulo;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;
  final String notasAdicionales;
  final List<String> imagenes;
  
  // Sync fields
  final int isSynced;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int isDeleted;

  // Relation
  final List<ArticuloCotizacionModel> articulos;

  CotizacionModel({
    String? id,
    this.userId,
    this.titulo = 'Cotización 1',
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    this.notasAdicionales = '',
    this.imagenes = const [],
    this.isSynced = 0,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.isDeleted = 0,
    this.articulos = const [],
  })  : id = id ?? const Uuid().v4(),
        fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now();

  double get montoTotal => articulos.fold(0, (sum, item) => sum + item.subtotal);
  double get totalArticulos => articulos.fold(0, (sum, item) => sum + item.cantidad);

  CotizacionModel copyWith({
    String? id,
    String? userId,
    String? titulo,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    String? notasAdicionales,
    List<String>? imagenes,
    int? isSynced,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    int? isDeleted,
    List<ArticuloCotizacionModel>? articulos,
  }) {
    return CotizacionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      notasAdicionales: notasAdicionales ?? this.notasAdicionales,
      imagenes: imagenes ?? this.imagenes,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      articulos: articulos ?? this.articulos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'titulo': titulo,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_modificacion': fechaModificacion.toIso8601String(),
      'notas_adicionales': notasAdicionales,
      'imagenes': json.encode(imagenes),
      'is_synced': isSynced,
      'sync_status': syncStatus.toValue(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory CotizacionModel.fromMap(Map<String, dynamic> map, {List<ArticuloCotizacionModel> articulos = const []}) {
    List<String> parsedImagenes = [];
    if (map['imagenes'] != null && map['imagenes'].toString().isNotEmpty) {
      try {
        parsedImagenes = List<String>.from(json.decode(map['imagenes']));
      } catch (e) {
        parsedImagenes = [];
      }
    }

    return CotizacionModel(
      id: map['id'] ?? '',
      userId: map['user_id'],
      titulo: map['titulo'] ?? '',
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
      fechaModificacion: DateTime.parse(map['fecha_modificacion']),
      notasAdicionales: map['notas_adicionales'] ?? '',
      imagenes: parsedImagenes,
      isSynced: map['is_synced']?.toInt() ?? 0,
      syncStatus: SyncStatus.fromValue(map['sync_status'] ?? 'pending'),
      lastSyncedAt: map['last_synced_at'] != null ? DateTime.parse(map['last_synced_at']) : null,
      isDeleted: map['is_deleted']?.toInt() ?? 0,
      articulos: articulos,
    );
  }
}
