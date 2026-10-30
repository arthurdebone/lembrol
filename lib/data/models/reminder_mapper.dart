import 'package:drift/drift.dart';
import '../../domain/entities/reminder.dart';
import '../datasources/database.dart';

class ReminderMapper {
  static Reminder toDomain(ReminderRow row) {
    final days = row.selectedDays
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toSet();

    return Reminder(
      id: row.id,
      title: row.title,
      description: row.description,
      startHour: row.startHour,
      startMinute: row.startMinute,
      endHour: row.endHour,
      endMinute: row.endMinute,
      intervalMinutes: row.intervalMinutes,
      selectedDays: days,
      isActive: row.isActive,
      category: row.category,
      enableVisual: row.enableVisual,
      enableSound: row.enableSound,
      enableVibration: row.enableVibration,
      snoozeUntil: row.snoozeUntil,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static RemindersTableCompanion toCompanion(Reminder reminder) {
    final daysStr = (reminder.selectedDays.toList()..sort()).join(',');

    return RemindersTableCompanion(
      id: Value(reminder.id),
      title: Value(reminder.title),
      description: Value(reminder.description),
      startHour: Value(reminder.startHour),
      startMinute: Value(reminder.startMinute),
      endHour: Value(reminder.endHour),
      endMinute: Value(reminder.endMinute),
      intervalMinutes: Value(reminder.intervalMinutes),
      selectedDays: Value(daysStr),
      isActive: Value(reminder.isActive),
      category: Value(reminder.category),
      enableVisual: Value(reminder.enableVisual),
      enableSound: Value(reminder.enableSound),
      enableVibration: Value(reminder.enableVibration),
      snoozeUntil: Value(reminder.snoozeUntil),
      createdAt: Value(reminder.createdAt),
      updatedAt: Value(reminder.updatedAt),
    );
  }
}
