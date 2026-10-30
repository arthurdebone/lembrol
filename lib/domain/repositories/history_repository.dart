import '../entities/reminder_log.dart';

abstract class HistoryRepository {
  Stream<List<ReminderLog>> watchAllLogs();
  Future<List<ReminderLog>> getAllLogs();
  Future<void> addLog(ReminderLog log);
  Future<void> updateLog(ReminderLog log);
  Future<void> clearHistory();
  Future<void> deleteLogsForReminder(String reminderId);
}
