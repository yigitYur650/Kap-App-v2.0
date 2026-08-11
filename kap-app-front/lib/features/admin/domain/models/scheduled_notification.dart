class ScheduledNotification {
  final String id;
  final String title;
  final String body;
  final String scheduledTime; // e.g. "12:00:00"
  final bool isActive;
  final String notificationType; // 'water', 'market', 'nutrition', 'custom'
  final DateTime? createdAt;

  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.isActive = true,
    this.notificationType = 'custom',
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduled_time': scheduledTime,
      'is_active': isActive,
      'notification_type': notificationType,
    };
  }

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      scheduledTime: json['scheduled_time'] as String? ?? '12:00:00',
      isActive: json['is_active'] as bool? ?? true,
      notificationType: json['notification_type'] as String? ?? 'custom',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  ScheduledNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? scheduledTime,
    bool? isActive,
    String? notificationType,
    DateTime? createdAt,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isActive: isActive ?? this.isActive,
      notificationType: notificationType ?? this.notificationType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
