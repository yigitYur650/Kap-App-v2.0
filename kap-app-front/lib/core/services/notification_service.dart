import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/admin/data/notification_admin_repository.dart';
import '../../features/admin/domain/models/scheduled_notification.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _flutterLocalNotificationsPlugin.initialize(initSettings);
    } catch (_) {}

    // Sync active daily notifications from Supabase
    await syncScheduledNotifications();
  }

  /// Show instant push notification on device
  Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kap_app_instant_channel',
      'Anlık Bildirimler',
      channelDescription: 'Kap-App anlık duyurular ve canlı grup bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (_) {}
  }

  /// Sync all active daily notifications from Supabase & schedule them locally
  Future<void> syncScheduledNotifications() async {
    try {
      final notifications = await _ref
          .read(notificationAdminRepositoryProvider)
          .getScheduledNotifications();

      // Cancel existing scheduled notifications first
      await _flutterLocalNotificationsPlugin.cancelAll();

      for (int i = 0; i < notifications.length; i++) {
        final item = notifications[i];
        if (item.isActive) {
          await _scheduleDailyNotification(item, notificationId: i + 100);
        }
      }
    } catch (_) {}
  }

  Future<void> _scheduleDailyNotification(
    ScheduledNotification item, {
    required int notificationId,
  }) async {
    final parts = item.scheduledTime.split(':');
    if (parts.length < 2) return;

    const androidDetails = AndroidNotificationDetails(
      'kap_app_scheduled_channel',
      'Otomatik Hatırlatıcılar',
      channelDescription: 'Kap-App su, market ve beslenme otomatik hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _flutterLocalNotificationsPlugin.periodicallyShow(
        notificationId,
        item.title,
        item.body,
        RepeatInterval.daily,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );
    } catch (_) {}
  }
}
