import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/qr_code_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Checks a list of QR codes and shows local alerts if expiring in <= 7 days
  Future<void> checkExpirationNotifications(List<QRCodeModel> qrCodes) async {
    for (final qr in qrCodes) {
      final days = qr.daysRemaining;
      if (days == 7 || days == 5 || days == 3) {
        await _showNotification(
          id: qr.id.hashCode,
          title: '⚠️ QR Próximo a Expirar',
          body: 'El QR de ${qr.banco} (${qr.referencia}) expira en $days días.',
        );
      } else if (days <= 0) {
        await _showNotification(
          id: qr.id.hashCode,
          title: '🚨 QR Expirado',
          body: 'El QR de ${qr.banco} (${qr.referencia}) ha expirado.',
        );
      }
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'soluro_expirations',
      'Expiración de QRs',
      channelDescription: 'Notificaciones sobre vencimiento de códigos QR de cobro',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
