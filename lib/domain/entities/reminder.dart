import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class Reminder {
  final String id;
  final String title;
  final String? description;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int intervalMinutes;
  final Set<int> selectedDays; // 1 = Monday, 7 = Sunday (ISO 8601)
  final bool isActive;
  final String? category;
  final bool enableVisual;
  final bool enableSound;
  final bool enableVibration;
  final DateTime? snoozeUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.intervalMinutes,
    required this.selectedDays,
    this.isActive = true,
    this.category,
    this.enableVisual = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.snoozeUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  int get startMinutesOfDay => startHour * 60 + startMinute;
  int get endMinutesOfDay => endHour * 60 + endMinute;

  bool isDaySelected(int isoWeekday) => selectedDays.contains(isoWeekday);

  bool isSnoozedAt(DateTime now) {
    if (snoozeUntil == null) return false;
    return snoozeUntil!.isAfter(now);
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    int? intervalMinutes,
    Set<int>? selectedDays,
    bool? isActive,
    String? category,
    bool? enableVisual,
    bool? enableSound,
    bool? enableVibration,
    DateTime? snoozeUntil,
    bool clearSnooze = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      selectedDays: selectedDays ?? this.selectedDays,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      enableVisual: enableVisual ?? this.enableVisual,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      snoozeUntil: clearSnooze ? null : (snoozeUntil ?? this.snoozeUntil),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          startHour == other.startHour &&
          startMinute == other.startMinute &&
          endHour == other.endHour &&
          endMinute == other.endMinute &&
          intervalMinutes == other.intervalMinutes &&
          setEquals(selectedDays, other.selectedDays) &&
          isActive == other.isActive &&
          category == other.category &&
          enableVisual == other.enableVisual &&
          enableSound == other.enableSound &&
          enableVibration == other.enableVibration &&
          snoozeUntil == other.snoozeUntil &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        startHour,
        startMinute,
        endHour,
        endMinute,
        intervalMinutes,
        Object.hashAll(selectedDays),
        isActive,
        category,
        enableVisual,
        enableSound,
        enableVibration,
        snoozeUntil,
        createdAt,
        updatedAt,
      );
}
