import 'package:uuid/uuid.dart';
import 'sync_status.dart';

class DireccionModel {
  final String id;
  final String? userId;
  final String titulo;
  final String detalle;
  final String urlMaps;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final bool isDeleted;

  DireccionModel({
    String? id,
    this.userId,
    required this.titulo,
    required this.detalle,
    required this.urlMaps,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DireccionModel copyWith({
    String? id,
    String? userId,
    String? titulo,
    String? detalle,
    String? urlMaps,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool? isDeleted,
  }) {
    return DireccionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      detalle: detalle ?? this.detalle,
      urlMaps: urlMaps ?? this.urlMaps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Serialización estándar JSON con formato ISO-8601 para DateTime.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'titulo': titulo,
      'detalle': detalle,
      'url_maps': urlMaps,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus.toValue(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Alias compatible con almacenamiento y base de datos local
  Map<String, dynamic> toMap() => toJson();

  factory DireccionModel.fromJson(Map<String, dynamic> json) {
    return DireccionModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      userId: (json['user_id'] ?? json['userId']) as String?,
      titulo: json['titulo'] as String? ?? '',
      detalle: json['detalle'] as String? ?? '',
      urlMaps: (json['url_maps'] ?? json['urlMaps']) as String? ?? '',
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.parse((json['created_at'] ?? json['createdAt']) as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse((json['updated_at'] ?? json['updatedAt']) as String)
          : DateTime.now(),
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

  /// Factory compatible con Map de SQLite
  factory DireccionModel.fromMap(Map<String, dynamic> map) =>
      DireccionModel.fromJson(map);

  /// Format specified by requirements for [Copy Info]:
  /// text: `titulo` \n `detalle` \n `url_maps`
  String get formattedCopyText {
    return '$titulo\n$detalle\n$urlMaps';
  }
}
