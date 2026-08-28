import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class QRCodeModel {
  final int? id;
  final String banco;
  final String referencia;
  final DateTime fechaExpiracion;
  final String rutaImagen;

  QRCodeModel({
    this.id,
    required this.banco,
    required this.referencia,
    required this.fechaExpiracion,
    required this.rutaImagen,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'banco': banco,
      'referencia': referencia,
      'fecha_expiracion': fechaExpiracion.toIso8601String(),
      'ruta_imagen': rutaImagen,
    };
  }

  factory QRCodeModel.fromMap(Map<String, dynamic> map) {
    return QRCodeModel(
      id: map['id'] as int?,
      banco: map['banco'] as String? ?? '',
      referencia: map['referencia'] as String? ?? '',
      fechaExpiracion: map['fecha_expiracion'] != null
          ? DateTime.parse(map['fecha_expiracion'] as String)
          : DateTime.now(),
      rutaImagen: map['ruta_imagen'] as String? ?? '',
    );
  }

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
