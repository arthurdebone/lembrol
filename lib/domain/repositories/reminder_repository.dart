import '../entities/reminder.dart';

abstract class ReminderRepository {
  Stream<List<Reminder>> watchAllReminders();
  Future<List<Reminder>> getAllReminders();
  Future<Reminder?> getReminderById(String id);
  Future<void> saveReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<void> toggleReminderActive(String id, bool isActive);
  Future<void> setSnooze(String id, DateTime? snoozeUntil);
}
