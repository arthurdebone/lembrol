import 'package:drift/drift.dart';
import '../../domain/entities/reminder_log.dart';
import '../datasources/database.dart';

class HistoryMapper {
  static ReminderLog toDomain(ReminderLogRow row) {
    return ReminderLog(
      id: row.id,
      reminderId: row.reminderId,
      reminderTitle: row.reminderTitle,
      scheduledTime: row.scheduledTime,
      processedTime: row.processedTime,
      status: ReminderLogStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => ReminderLogStatus.delivered,
      ),
      userAction: row.userAction,
      note: row.note,
      createdAt: row.createdAt,
    );
  }

  static ReminderLogsTableCompanion toCompanion(ReminderLog log) {
    return ReminderLogsTableCompanion(
      id: Value(log.id),
      reminderId: Value(log.reminderId),
      reminderTitle: Value(log.reminderTitle),
      scheduledTime: Value(log.scheduledTime),
      processedTime: Value(log.processedTime),
      status: Value(log.status.name),
      userAction: Value(log.userAction),
      note: Value(log.note),
      createdAt: Value(log.createdAt),
    );
  }
}
