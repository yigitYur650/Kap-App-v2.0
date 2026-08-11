import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/scheduled_notification.dart';

final notificationAdminRepositoryProvider = Provider<NotificationAdminRepository>((ref) {
  return NotificationAdminRepository(Supabase.instance.client);
});

final scheduledNotificationsProvider = FutureProvider<List<ScheduledNotification>>((ref) async {
  final repo = ref.watch(notificationAdminRepositoryProvider);
  return repo.getScheduledNotifications();
});

class NotificationAdminRepository {
  final SupabaseClient _supabase;

  NotificationAdminRepository(this._supabase);

  /// Fetch all scheduled automated notifications from Supabase
  Future<List<ScheduledNotification>> getScheduledNotifications() async {
    try {
      final response = await _supabase
          .from('scheduled_notifications')
          .select()
          .order('scheduled_time', ascending: true);

      return (response as List)
          .map((item) => ScheduledNotification.fromJson(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Create or update a scheduled notification
  Future<void> saveScheduledNotification(ScheduledNotification notification) async {
    final data = {
      if (notification.id.isNotEmpty) 'id': notification.id,
      'title': notification.title,
      'body': notification.body,
      'scheduled_time': notification.scheduledTime,
      'is_active': notification.isActive,
      'notification_type': notification.notificationType,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('scheduled_notifications').upsert(data);
  }

  /// Toggle active/passive status of a notification
  Future<void> toggleNotificationStatus(String id, bool isActive) async {
    await _supabase
        .from('scheduled_notifications')
        .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  /// Delete a scheduled notification
  Future<void> deleteScheduledNotification(String id) async {
    await _supabase
        .from('scheduled_notifications')
        .delete()
        .eq('id', id);
  }
}
