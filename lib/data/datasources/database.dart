import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('ReminderRow')
class RemindersTable extends Table {
  @override
  String get tableName => 'reminders';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 80)();
  TextColumn get description => text().nullable()();
  IntColumn get startHour => integer()();
  IntColumn get startMinute => integer()();
  IntColumn get endHour => integer()();
  IntColumn get endMinute => integer()();
  IntColumn get intervalMinutes => integer()();
  TextColumn get selectedDays => text()(); // Ex: "1,2,3,4,5"
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get category => text().nullable()();
  BoolColumn get enableVisual => boolean().withDefault(const Constant(true))();
  BoolColumn get enableSound => boolean().withDefault(const Constant(true))();
  BoolColumn get enableVibration => boolean().withDefault(const Constant(true))();
  DateTimeColumn get snoozeUntil => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReminderLogRow')
class ReminderLogsTable extends Table {
  @override
  String get tableName => 'reminder_logs';

  TextColumn get id => text()();
  TextColumn get reminderId => text()();
  TextColumn get reminderTitle => text()();
  DateTimeColumn get scheduledTime => dateTime()();
  DateTimeColumn get processedTime => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get userAction => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppSettingRow')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [RemindersTable, ReminderLogsTable, AppSettingsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'lembrol.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
