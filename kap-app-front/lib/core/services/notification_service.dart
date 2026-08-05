import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  RealtimeChannel? _adminNotifChannel;
  bool _isInitialized = false;

  /// Initializes local notifications, Firebase Messaging, and permissions.
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Create high priority notification channel for Android v2
    const androidChannel = AndroidNotificationChannel(
      'kap_app_admin_channel_v2',
      'Kap-App Duyuruları',
      description: 'Yöneticiler tarafından gönderilen duyuru ve bildirimler',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Request Android 13+ runtime notification permissions
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Firebase Messaging FCM Permission & Foreground Listener Setup
    if (!kIsWeb) {
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('[FCM] Foreground message received: ${message.notification?.title}');
          final notification = message.notification;
          if (notification != null) {
            _showSystemNotification(notification.title ?? 'Duyuru', notification.body ?? '');
          }
        });

        final fcmToken = await messaging.getToken();
        debugPrint('[FCM Token] $fcmToken');
      } catch (e) {
        debugPrint('[FCM] Initialization warning: $e');
      }
    }

    _isInitialized = true;
  }

  /// Listens to real-time admin push notifications from Supabase.
  void startListening(BuildContext context) {
    if (_adminNotifChannel != null) return;

    debugPrint('[NotificationService] Starting Realtime subscription on public:push_notifications...');

    _adminNotifChannel = Supabase.instance.client
        .channel('public:push_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'push_notifications',
          callback: (payload) {
            debugPrint('[NotificationService] Realtime payload received: ${payload.newRecord}');
            final record = payload.newRecord;
            final title = record['title'] as String? ?? 'Yönetici Bildirimi';
            final body = record['body'] as String? ?? '';

            if (body.isNotEmpty) {
              _showSystemNotification(title, body);
              _showInAppNotification(context, title, body);
            }
          },
        )
        .subscribe((status, [error]) {
          debugPrint('[NotificationService] Subscription status: $status, error: $error');
        });
  }

  /// Shows a native heads-up system notification bar.
  Future<void> _showSystemNotification(String title, String body) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'kap_app_admin_channel_v2',
        'Kap-App Duyuruları',
        channelDescription: 'Yöneticiler tarafından gönderilen duyuru ve bildirimler',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
      debugPrint('[NotificationService] Native system notification displayed!');
    } catch (e, st) {
      debugPrint('[NotificationService] Error showing system notification: $e\n$st');
    }
  }

  /// Shows an in-app banner for active app users.
  void _showInAppNotification(BuildContext context, String title, String body) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1F2022),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLg.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: AppTypography.bodyLg.copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void stopListening() {
    _adminNotifChannel?.unsubscribe();
    _adminNotifChannel = null;
  }
}
