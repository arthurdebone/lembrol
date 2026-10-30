import 'package:drift/drift.dart';
import '../../domain/entities/reminder_log.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/database.dart';
import '../models/history_mapper.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final AppDatabase _db;

  HistoryRepositoryImpl(this._db);

  @override
  Stream<List<ReminderLog>> watchAllLogs() {
    return (_db.select(_db.reminderLogsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(HistoryMapper.toDomain).toList());
  }

  @override
  Future<List<ReminderLog>> getAllLogs() async {
    final rows = await (_db.select(_db.reminderLogsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(HistoryMapper.toDomain).toList();
  }

  @override
  Future<void> addLog(ReminderLog log) async {
    await _db
        .into(_db.reminderLogsTable)
        .insertOnConflictUpdate(HistoryMapper.toCompanion(log));
  }

  @override
  Future<void> updateLog(ReminderLog log) async {
    await _db
        .into(_db.reminderLogsTable)
        .insertOnConflictUpdate(HistoryMapper.toCompanion(log));
  }

  @override
  Future<void> clearHistory() async {
    await _db.delete(_db.reminderLogsTable).go();
  }

  @override
  Future<void> deleteLogsForReminder(String reminderId) async {
    await (_db.delete(_db.reminderLogsTable)
          ..where((t) => t.reminderId.equals(reminderId)))
        .go();
  }
}
