import 'package:drift/drift.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/database.dart';
import '../models/reminder_mapper.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final AppDatabase _db;

  ReminderRepositoryImpl(this._db);

  @override
  Stream<List<Reminder>> watchAllReminders() {
    return (_db.select(_db.remindersTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.startHour),
            (t) => OrderingTerm(expression: t.startMinute),
          ]))
        .watch()
        .map((rows) => rows.map(ReminderMapper.toDomain).toList());
  }

  @override
  Future<List<Reminder>> getAllReminders() async {
    final rows = await (_db.select(_db.remindersTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.startHour),
            (t) => OrderingTerm(expression: t.startMinute),
          ]))
        .get();
    return rows.map(ReminderMapper.toDomain).toList();
  }

  @override
  Future<Reminder?> getReminderById(String id) async {
    final query = _db.select(_db.remindersTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? ReminderMapper.toDomain(row) : null;
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    await _db
        .into(_db.remindersTable)
        .insertOnConflictUpdate(ReminderMapper.toCompanion(reminder));
  }

  @override
  Future<void> deleteReminder(String id) async {
    await (_db.delete(_db.remindersTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> toggleReminderActive(String id, bool isActive) async {
    await (_db.update(_db.remindersTable)..where((t) => t.id.equals(id))).write(
      RemindersTableCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> setSnooze(String id, DateTime? snoozeUntil) async {
    await (_db.update(_db.remindersTable)..where((t) => t.id.equals(id))).write(
      RemindersTableCompanion(
        snoozeUntil: Value(snoozeUntil),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
