import 'package:flutter/foundation.dart';

enum ReminderLogStatus {
  scheduled,
  delivered,
  completed,
  snoozed,
  dismissed;

  String get label {
    switch (this) {
      case ReminderLogStatus.scheduled:
        return 'Agendado';
      case ReminderLogStatus.delivered:
        return 'Disparado';
      case ReminderLogStatus.completed:
        return 'Concluído';
      case ReminderLogStatus.snoozed:
        return 'Adiado';
      case ReminderLogStatus.dismissed:
        return 'Ignorado';
    }
  }
}

@immutable
class ReminderLog {
  final String id;
  final String reminderId;
  final String reminderTitle;
  final DateTime scheduledTime;
  final DateTime? processedTime;
  final ReminderLogStatus status;
  final String? userAction;
  final String? note;
  final DateTime createdAt;

  const ReminderLog({
    required this.id,
    required this.reminderId,
    required this.reminderTitle,
    required this.scheduledTime,
    this.processedTime,
    required this.status,
    this.userAction,
    this.note,
    required this.createdAt,
  });

  ReminderLog copyWith({
    String? id,
    String? reminderId,
    String? reminderTitle,
    DateTime? scheduledTime,
    DateTime? processedTime,
    ReminderLogStatus? status,
    String? userAction,
    String? note,
    DateTime? createdAt,
  }) {
    return ReminderLog(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      reminderTitle: reminderTitle ?? this.reminderTitle,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      processedTime: processedTime ?? this.processedTime,
      status: status ?? this.status,
      userAction: userAction ?? this.userAction,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          reminderId == other.reminderId &&
          reminderTitle == other.reminderTitle &&
          scheduledTime == other.scheduledTime &&
          processedTime == other.processedTime &&
          status == other.status &&
          userAction == other.userAction &&
          note == other.note &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        reminderId,
        reminderTitle,
        scheduledTime,
        processedTime,
        status,
        userAction,
        note,
        createdAt,
      );
}
