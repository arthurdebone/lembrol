import 'package:flutter/material.dart';
import '../entities/reminder.dart';
import 'recurrence_validator.dart';

class RecurrenceEngine {
  /// Gera a grade de horários (em TimeOfDay) para o intervalo diário configurado.
  /// Regras:
  /// - Começa exatamente em startTime.
  /// - Incrementa pelo intervalMinutes.
  /// - endTime é inclusivo (se o horário coincidir com endTime, ele é incluído).
  /// - Nenhum disparo ultrapassa endTime.
  static List<TimeOfDay> calculateDaySchedule({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required int intervalMinutes,
  }) {
    final validation = RecurrenceValidator.validateTimeWindow(
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
    );
    if (!validation.isValid) return const [];

    final intervalVal = RecurrenceValidator.validateInterval(intervalMinutes);
    if (!intervalVal.isValid) return const [];

    final List<TimeOfDay> schedule = [];
    final startTotal = startHour * 60 + startMinute;
    final endTotal = endHour * 60 + endMinute;

    int current = startTotal;
    while (current <= endTotal) {
      final hour = current ~/ 60;
      final minute = current % 60;
      schedule.add(TimeOfDay(hour: hour, minute: minute));

      current += intervalMinutes;
    }

    return schedule;
  }

  /// Calcula o próximo disparo para um lembrete a partir de uma data/hora de referência.
  /// Retorna `null` se o lembrete estiver inativo, sem dias válidos ou com configurações inválidas.
  static DateTime? getNextOccurrence({
    required Reminder reminder,
    required DateTime fromDateTime,
  }) {
    if (!reminder.isActive) return null;
    if (reminder.selectedDays.isEmpty) return null;

    final validation = RecurrenceValidator.validateAll(
      title: reminder.title,
      intervalMinutes: reminder.intervalMinutes,
      startHour: reminder.startHour,
      startMinute: reminder.startMinute,
      endHour: reminder.endHour,
      endMinute: reminder.endMinute,
      selectedDays: reminder.selectedDays,
    );
    if (!validation.isValid) return null;

    final reference = fromDateTime.toLocal();

    // 1. Verifica adiamento (snooze) ativo
    final snooze = reminder.snoozeUntil?.toLocal();
    final hasActiveSnooze = snooze != null && snooze.isAfter(reference);

    // 2. Procura a próxima ocorrência regular
    DateTime? nextRegular;

    // Checa hoje primeiro
    if (reminder.selectedDays.contains(reference.weekday)) {
      final todaySchedule = calculateDaySchedule(
        startHour: reminder.startHour,
        startMinute: reminder.startMinute,
        endHour: reminder.endHour,
        endMinute: reminder.endMinute,
        intervalMinutes: reminder.intervalMinutes,
      );

      for (final tod in todaySchedule) {
        final occurrence = DateTime(
          reference.year,
          reference.month,
          reference.day,
          tod.hour,
          tod.minute,
        );

        if (occurrence.isAfter(reference)) {
          nextRegular = occurrence;
          break;
        }
      }
    }

    // Se hoje não tem mais disparos ou não está selecionado, procura nos próximos 7 dias
    if (nextRegular == null) {
      for (int i = 1; i <= 7; i++) {
        final nextDay = reference.add(Duration(days: i));
        if (reminder.selectedDays.contains(nextDay.weekday)) {
          nextRegular = DateTime(
            nextDay.year,
            nextDay.month,
            nextDay.day,
            reminder.startHour,
            reminder.startMinute,
          );
          break;
        }
      }
    }

    if (hasActiveSnooze) {
      // O adiamento sobrepõe se for anterior ou se a ocorrência regular for muito posterior
      if (nextRegular == null || snooze.isBefore(nextRegular)) {
        return snooze;
      }
    }

    return nextRegular;
  }

  /// Retorna as próximas `limit` ocorrências para exibição em prévias e listas.
  static List<DateTime> getUpcomingOccurrences({
    required Reminder reminder,
    required DateTime fromDateTime,
    int limit = 5,
  }) {
    if (!reminder.isActive || reminder.selectedDays.isEmpty || limit <= 0) {
      return const [];
    }

    final validation = RecurrenceValidator.validateAll(
      title: reminder.title,
      intervalMinutes: reminder.intervalMinutes,
      startHour: reminder.startHour,
      startMinute: reminder.startMinute,
      endHour: reminder.endHour,
      endMinute: reminder.endMinute,
      selectedDays: reminder.selectedDays,
    );
    if (!validation.isValid) return const [];

    final List<DateTime> occurrences = [];
    DateTime currentRef = fromDateTime.toLocal();

    // Se houver snooze ativo, a primeira ocorrência é o snooze
    final snooze = reminder.snoozeUntil?.toLocal();
    if (snooze != null && snooze.isAfter(currentRef)) {
      occurrences.add(snooze);
      if (occurrences.length >= limit) return occurrences;
    }

    // Geramos as próximas ocorrências sem considerar o snooze (sequência regular)
    final reminderWithoutSnooze = reminder.copyWith(clearSnooze: true);

    while (occurrences.length < limit) {
      final next = getNextOccurrence(
        reminder: reminderWithoutSnooze,
        fromDateTime: currentRef,
      );

      if (next == null) break;

      // Evita duplicatas se coincidir com o snooze
      if (!occurrences.contains(next)) {
        occurrences.add(next);
      }

      // Avança a referência para após o disparo encontrado (1 segundo à frente)
      currentRef = next.add(const Duration(seconds: 1));
    }

    return occurrences;
  }

  /// Calcula a duração restante entre a referência atual e o próximo disparo.
  static Duration calculateTimeRemaining({
    required DateTime nextOccurrence,
    required DateTime fromDateTime,
  }) {
    final diff = nextOccurrence.difference(fromDateTime);
    return diff.isNegative ? Duration.zero : diff;
  }
}
