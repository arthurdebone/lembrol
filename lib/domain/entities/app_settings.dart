import 'package:flutter/material.dart';

@immutable
class AppSettings {
  final ThemeMode themeMode;
  final int defaultSnoozeMinutes;
  final bool defaultSound;
  final bool defaultVibration;
  final bool autostartOnWindows;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultSnoozeMinutes = 10,
    this.defaultSound = true,
    this.defaultVibration = true,
    this.autostartOnWindows = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? defaultSnoozeMinutes,
    bool? defaultSound,
    bool? defaultVibration,
    bool? autostartOnWindows,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
      defaultSound: defaultSound ?? this.defaultSound,
      defaultVibration: defaultVibration ?? this.defaultVibration,
      autostartOnWindows: autostartOnWindows ?? this.autostartOnWindows,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          defaultSnoozeMinutes == other.defaultSnoozeMinutes &&
          defaultSound == other.defaultSound &&
          defaultVibration == other.defaultVibration &&
          autostartOnWindows == other.autostartOnWindows;

  @override
  int get hashCode => Object.hash(
        themeMode,
        defaultSnoozeMinutes,
        defaultSound,
        defaultVibration,
        autostartOnWindows,
      );
}
