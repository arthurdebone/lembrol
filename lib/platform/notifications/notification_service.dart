abstract class NotificationService {
  Future<void> initialize({
    void Function(String reminderId, String? action)? onNotificationAction,
  });

  Future<bool> requestPermissions();
  Future<bool> hasNotificationPermissions();
  Future<bool> canScheduleExactAlarms();

  Future<void> scheduleNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    bool sound = true,
    bool vibration = true,
    String? payload,
  });

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    String? body,
    bool sound = true,
    bool vibration = true,
    String? payload,
  });

  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();

  static int getStableNotificationId(String reminderId, [int occurrenceIndex = 0]) {
    final hash = reminderId.hashCode ^ (occurrenceIndex * 31);
    return hash & 0x7FFFFFFF;
  }
}
