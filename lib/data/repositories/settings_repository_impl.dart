import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/database.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _db;

  static const String _settingsKey = 'app_config';

  SettingsRepositoryImpl(this._db);

  @override
  Stream<AppSettings> watchSettings() {
    return (_db.select(_db.appSettingsTable)
          ..where((t) => t.key.equals(_settingsKey)))
        .watchSingleOrNull()
        .map((row) => row != null ? _parseJson(row.value) : const AppSettings());
  }

  @override
  Future<AppSettings> getSettings() async {
    final query = _db.select(_db.appSettingsTable)
      ..where((t) => t.key.equals(_settingsKey));
    final row = await query.getSingleOrNull();
    return row != null ? _parseJson(row.value) : const AppSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final jsonStr = jsonEncode({
      'themeMode': settings.themeMode.name,
      'defaultSnoozeMinutes': settings.defaultSnoozeMinutes,
      'defaultSound': settings.defaultSound,
      'defaultVibration': settings.defaultVibration,
      'autostartOnWindows': settings.autostartOnWindows,
    });

    await _db.into(_db.appSettingsTable).insertOnConflictUpdate(
          AppSettingsTableCompanion(
            key: const Value(_settingsKey),
            value: Value(jsonStr),
          ),
        );
  }

  AppSettings _parseJson(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final themeStr = map['themeMode'] as String? ?? 'system';
      final themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => ThemeMode.system,
      );

      return AppSettings(
        themeMode: themeMode,
        defaultSnoozeMinutes: map['defaultSnoozeMinutes'] as int? ?? 10,
        defaultSound: map['defaultSound'] as bool? ?? true,
        defaultVibration: map['defaultVibration'] as bool? ?? true,
        autostartOnWindows: map['autostartOnWindows'] as bool? ?? false,
      );
    } catch (_) {
      return const AppSettings();
    }
  }
}
