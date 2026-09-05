import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';
import 'sync_status.dart';

class QRCodeModel {
  final String id;
  final String? userId;
  final String banco;
  final String referencia;
  final DateTime fechaExpiracion;
  final String rutaImagen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final bool isDeleted;

  QRCodeModel({
    String? id,
    this.userId,
    required this.banco,
    required this.referencia,
    required this.fechaExpiracion,
    required this.rutaImagen,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  QRCodeModel copyWith({
    String? id,
    String? userId,
    String? banco,
    String? referencia,
    DateTime? fechaExpiracion,
    String? rutaImagen,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool? isDeleted,
  }) {
    return QRCodeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      banco: banco ?? this.banco,
      referencia: referencia ?? this.referencia,
      fechaExpiracion: fechaExpiracion ?? this.fechaExpiracion,
      rutaImagen: rutaImagen ?? this.rutaImagen,
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
      'banco': banco,
      'referencia': referencia,
      'fecha_expiracion': fechaExpiracion.toIso8601String(),
      'ruta_imagen': rutaImagen,
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

  factory QRCodeModel.fromJson(Map<String, dynamic> json) {
    return QRCodeModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      userId: (json['user_id'] ?? json['userId']) as String?,
      banco: json['banco'] as String? ?? '',
      referencia: json['referencia'] as String? ?? '',
      fechaExpiracion: json['fecha_expiracion'] != null || json['fechaExpiracion'] != null
          ? DateTime.parse((json['fecha_expiracion'] ?? json['fechaExpiracion']) as String)
          : DateTime.now(),
      rutaImagen: (json['ruta_imagen'] ?? json['rutaImagen']) as String? ?? '',
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
  factory QRCodeModel.fromMap(Map<String, dynamic> map) =>
      QRCodeModel.fromJson(map);

  /// Returns total days remaining until expiration date
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expDate = DateTime(fechaExpiracion.year, fechaExpiracion.month, fechaExpiracion.day);
    return expDate.difference(today).inDays;
  }

  /// Text color according to expiration days:
  /// > 7 days: Green
  /// 3 to 7 days: Yellow
  /// < 3 days: Red
  Color get statusTextColor {
    final days = daysRemaining;
    if (days > 7) {
      return AppColors.statusGreenText;
    } else if (days >= 3) {
      return AppColors.statusYellowText;
    } else {
      return AppColors.statusRedText;
    }
  }

  /// Background color for expiration badge
  Color get statusBackgroundColor {
    final days = daysRemaining;
    if (days > 7) {
      return AppColors.statusGreenBg;
    } else if (days >= 3) {
      return AppColors.statusYellowBg;
    } else {
      return AppColors.statusRedBg;
    }
  }

  /// Formatted status label
  String get statusText {
    final days = daysRemaining;
    if (days < 0) {
      return 'Expirado hace ${days.abs()} días';
    } else if (days == 0) {
      return 'Expira hoy';
    } else if (days == 1) {
      return 'Expira en 1 día';
    } else {
      return 'Expira en $days días';
    }
  }
}
