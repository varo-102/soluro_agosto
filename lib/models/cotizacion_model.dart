import 'package:uuid/uuid.dart';
import 'sync_status.dart';

class CotizacionModel {
  final String id;
  final String titulo;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;
  final String notasAdicionales;
  final bool isSynced;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final bool isDeleted;

  CotizacionModel({
    String? id,
    this.titulo = 'Cotización 1',
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    this.notasAdicionales = '',
    this.isSynced = false,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now();

  CotizacionModel copyWith({
    String? id,
    String? titulo,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    String? notasAdicionales,
    bool? isSynced,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool? isDeleted,
  }) {
    return CotizacionModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      notasAdicionales: notasAdicionales ?? this.notasAdicionales,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_modificacion': fechaModificacion.toIso8601String(),
      'notas_adicionales': notasAdicionales,
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus.toValue(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory CotizacionModel.fromJson(Map<String, dynamic> json) {
    return CotizacionModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      titulo: json['titulo'] as String? ?? 'Cotización 1',
      fechaCreacion: json['fecha_creacion'] != null || json['fechaCreacion'] != null
          ? DateTime.parse((json['fecha_creacion'] ?? json['fechaCreacion']) as String)
          : DateTime.now(),
      fechaModificacion: json['fecha_modificacion'] != null || json['fechaModificacion'] != null
          ? DateTime.parse((json['fecha_modificacion'] ?? json['fechaModificacion']) as String)
          : DateTime.now(),
      notasAdicionales: json['notas_adicionales'] as String? ?? '',
      isSynced: (json['is_synced'] ?? json['isSynced']) == 1 ||
          (json['is_synced'] ?? json['isSynced']) == true,
      syncStatus: SyncStatus.fromValue(
        (json['sync_status'] ?? json['syncStatus']) as String?,
      ),
      lastSyncedAt: json['last_synced_at'] != null || json['lastSyncedAt'] != null
          ? DateTime.parse((json['last_synced_at'] ?? json['lastSyncedAt']) as String)
          : null,
      isDeleted: (json['is_deleted'] ?? json['isDeleted']) == 1 ||
          (json['is_deleted'] ?? json['isDeleted']) == true,
    );
  }

  factory CotizacionModel.fromMap(Map<String, dynamic> map) => CotizacionModel.fromJson(map);
}
