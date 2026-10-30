import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lembrol/core/clock.dart';
import 'package:lembrol/domain/entities/reminder.dart';
import 'package:lembrol/domain/recurrence/recurrence_engine.dart';
import 'package:lembrol/domain/recurrence/recurrence_validator.dart';

void main() {
  group('RecurrenceEngine - Testes Obrigatórios das Regras de Negócio', () {
    // 1. Início às 08:00, fim às 12:00 e intervalo de 60 minutos
    test('Cenário 1: Início às 08:00, fim às 12:00 e intervalo de 60 minutos', () {
      final schedule = RecurrenceEngine.calculateDaySchedule(
        startHour: 8,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        intervalMinutes: 60,
      );

      expect(schedule.length, equals(5));
      expect(schedule[0], equals(const TimeOfDay(hour: 8, minute: 0)));
      expect(schedule[1], equals(const TimeOfDay(hour: 9, minute: 0)));
      expect(schedule[2], equals(const TimeOfDay(hour: 10, minute: 0)));
      expect(schedule[3], equals(const TimeOfDay(hour: 11, minute: 0)));
      expect(schedule[4], equals(const TimeOfDay(hour: 12, minute: 0)));
    });

    // 2. Início às 08:00, fim às 10:00 e intervalo de 45 minutos
    test('Cenário 2: Início às 08:00, fim às 10:00 e intervalo de 45 minutos', () {
      final schedule = RecurrenceEngine.calculateDaySchedule(
        startHour: 8,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
        intervalMinutes: 45,
      );

      expect(schedule.length, equals(3));
      expect(schedule[0], equals(const TimeOfDay(hour: 8, minute: 0)));
      expect(schedule[1], equals(const TimeOfDay(hour: 8, minute: 45)));
      expect(schedule[2], equals(const TimeOfDay(hour: 9, minute: 30)));
      // 10:15 ultrapassaria o horário final (10:00), então não deve ser incluído
    });

    // 3. Disparo exatamente no horário final
    test('Cenário 3: Disparo exatamente no horário final (inclusivo)', () {
      final schedule = RecurrenceEngine.calculateDaySchedule(
        startHour: 9,
        startMinute: 0,
        endHour: 11,
        endMinute: 0,
        intervalMinutes: 30,
      );

      expect(schedule.length, equals(5));
      expect(schedule.last, equals(const TimeOfDay(hour: 11, minute: 0)));
    });

    // 4. Intervalo que não divide a janela
    test('Cenário 4: Intervalo que não divide a janela perfeitamente', () {
      // 08:00 às 11:00 (180 min total). Intervalo de 50 min.
      // 08:00 (0m), 08:50 (50m), 09:40 (100m), 10:30 (150m). Próximo seria 11:20 (> 11:00).
      final schedule = RecurrenceEngine.calculateDaySchedule(
        startHour: 8,
        startMinute: 0,
        endHour: 11,
        endMinute: 0,
        intervalMinutes: 50,
      );

      expect(schedule.length, equals(4));
      expect(schedule.last, equals(const TimeOfDay(hour: 10, minute: 30)));
    });

    // 5. Dias da semana selecionados e não selecionados
    test('Cenário 5: Dias da semana selecionados e não selecionados', () {
      final reminder = Reminder(
        id: 'rem-5',
        title: 'Água dias úteis',
        startHour: 8,
        startMinute: 0,
        endHour: 18,
        endMinute: 0,
        intervalMinutes: 60,
        selectedDays: {1, 2, 3, 4, 5}, // Segunda a Sexta
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      // Simula Sábado, 31 de Outubro de 2026 às 10:00 (dia não selecionado)
      // O próximo disparo deve ser na Segunda-feira seguinte (02/11/2026) às 08:00
      final saturday = DateTime(2026, 10, 31, 10, 0);
      final nextFromSaturday = RecurrenceEngine.getNextOccurrence(
        reminder: reminder,
        fromDateTime: saturday,
      );

      expect(nextFromSaturday, isNotNull);
      expect(nextFromSaturday!.weekday, equals(DateTime.monday));
      expect(nextFromSaturday.hour, equals(8));
      expect(nextFromSaturday.minute, equals(0));

      // Simula Terça-feira, 27 de Outubro de 2026 às 07:30 (antes do início)
      final tuesdayEarly = DateTime(2026, 10, 27, 7, 30);
      final nextFromTuesday = RecurrenceEngine.getNextOccurrence(
        reminder: reminder,
        fromDateTime: tuesdayEarly,
      );

      expect(nextFromTuesday, isNotNull);
      expect(nextFromTuesday!.day, equals(27));
      expect(nextFromTuesday.hour, equals(8));
      expect(nextFromTuesday.minute, equals(0));
    });

    // 6. Lembrete desativado
    test('Cenário 6: Lembrete desativado não gera novos disparos', () {
      final inactiveReminder = Reminder(
        id: 'rem-6',
        title: 'Pausado',
        startHour: 8,
        startMinute: 0,
        endHour: 18,
        endMinute: 0,
        intervalMinutes: 60,
        selectedDays: {1, 2, 3, 4, 5, 6, 7},
        isActive: false,
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      final next = RecurrenceEngine.getNextOccurrence(
        reminder: inactiveReminder,
        fromDateTime: DateTime(2026, 10, 27, 8, 0),
      );

      final upcoming = RecurrenceEngine.getUpcomingOccurrences(
        reminder: inactiveReminder,
        fromDateTime: DateTime(2026, 10, 27, 8, 0),
      );

      expect(next, isNull);
      expect(upcoming, isEmpty);
    });

    // 7. Edição do intervalo
    test('Cenário 7: Edição do intervalo recalcula disparos corretamente', () {
      final original = Reminder(
        id: 'rem-7',
        title: 'Alongar',
        startHour: 8,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
        intervalMinutes: 60,
        selectedDays: {DateTime.tuesday}, // Apenas hoje
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      final ref = DateTime(2026, 10, 27, 8, 0); // Terça-feira

      // Original com 60m: disparos às 08:00, 09:00, 10:00. A partir de 08:00 restam 09:00 e 10:00
      final originalSchedule = RecurrenceEngine.calculateDaySchedule(
        startHour: original.startHour,
        startMinute: original.startMinute,
        endHour: original.endHour,
        endMinute: original.endMinute,
        intervalMinutes: original.intervalMinutes,
      );
      expect(originalSchedule.length, equals(3));
      expect(originalSchedule[1], equals(const TimeOfDay(hour: 9, minute: 0)));

      // Edita para intervalo de 30 minutos: 08:00, 08:30, 09:00, 09:30, 10:00
      final edited = original.copyWith(intervalMinutes: 30);
      final editedSchedule = RecurrenceEngine.calculateDaySchedule(
        startHour: edited.startHour,
        startMinute: edited.startMinute,
        endHour: edited.endHour,
        endMinute: edited.endMinute,
        intervalMinutes: edited.intervalMinutes,
      );
      expect(editedSchedule.length, equals(5));
      expect(editedSchedule[1], equals(const TimeOfDay(hour: 8, minute: 30)));
      expect(editedSchedule[2], equals(const TimeOfDay(hour: 9, minute: 0)));

      // Próxima ocorrência recalculada reflete a edição
      final nextAfterEdit = RecurrenceEngine.getNextOccurrence(
        reminder: edited,
        fromDateTime: ref,
      );
      expect(nextAfterEdit, equals(DateTime(2026, 10, 27, 8, 30)));
    });

    // 8. Edição dos horários
    test('Cenário 8: Edição dos horários inicial e final', () {
      final reminder = Reminder(
        id: 'rem-8',
        title: 'Pausa',
        startHour: 8,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
        intervalMinutes: 60,
        selectedDays: {DateTime.tuesday},
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      final edited = reminder.copyWith(
        startHour: 14,
        startMinute: 0,
        endHour: 16,
        endMinute: 0,
      );

      final schedule = RecurrenceEngine.calculateDaySchedule(
        startHour: edited.startHour,
        startMinute: edited.startMinute,
        endHour: edited.endHour,
        endMinute: edited.endMinute,
        intervalMinutes: edited.intervalMinutes,
      );

      expect(schedule.length, equals(3));
      expect(schedule.first, equals(const TimeOfDay(hour: 14, minute: 0)));
      expect(schedule.last, equals(const TimeOfDay(hour: 16, minute: 0)));
    });

    // 9. Cancelamento de agendamentos antigos
    test('Cenário 9: Cancelamento de agendamentos ao desativar ou deletar', () {
      final active = Reminder(
        id: 'rem-9',
        title: 'Ativo',
        startHour: 8,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        intervalMinutes: 60,
        selectedDays: {1, 2, 3, 4, 5, 6, 7},
        isActive: true,
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      final nextActive = RecurrenceEngine.getNextOccurrence(
        reminder: active,
        fromDateTime: DateTime(2026, 10, 27, 7, 0),
      );
      expect(nextActive, isNotNull);

      // Desativado / Cancelado
      final cancelled = active.copyWith(isActive: false);
      final nextCancelled = RecurrenceEngine.getNextOccurrence(
        reminder: cancelled,
        fromDateTime: DateTime(2026, 10, 27, 7, 0),
      );
      expect(nextCancelled, isNull);
    });

    // 10. Lembretes simultâneos
    test('Cenário 10: Lembretes simultâneos no mesmo horário', () {
      final reminderA = Reminder(
        id: 'rem-10-A',
        title: 'Água',
        startHour: 8,
        startMinute: 0,
        endHour: 18,
        endMinute: 0,
        intervalMinutes: 60,
        selectedDays: {1, 2, 3, 4, 5},
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      final reminderB = Reminder(
        id: 'rem-10-B',
        title: 'Olhos',
        startHour: 8,
        startMinute: 0,
        endHour: 18,
        endMinute: 0,
        intervalMinutes: 30,
        selectedDays: {1, 2, 3, 4, 5},
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      final ref = DateTime(2026, 10, 27, 7, 0);
      final nextA = RecurrenceEngine.getNextOccurrence(
        reminder: reminderA,
        fromDateTime: ref,
      );
      final nextB = RecurrenceEngine.getNextOccurrence(
        reminder: reminderB,
        fromDateTime: ref,
      );

      // Ambos disparam às 08:00 no mesmo instante sem colisão
      expect(nextA, equals(nextB));
      expect(nextA!.hour, equals(8));
      expect(reminderA.id, isNot(equals(reminderB.id)));
    });

    // 11. Adiamento sem alteração da sequência regular
    test('Cenário 11: Adiamento (snooze) sem alteração da sequência regular', () {
      final clock = SettableClock(DateTime(2026, 10, 27, 8, 0)); // 08:00
      final reminder = Reminder(
        id: 'rem-11',
        title: 'Água com Snooze',
        startHour: 8,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        intervalMinutes: 60,
        selectedDays: {1, 2, 3, 4, 5, 6, 7},
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      // Usuário adia 15 minutos às 08:00 -> novo disparo às 08:15
      final snoozedReminder = reminder.copyWith(
        snoozeUntil: DateTime(2026, 10, 27, 8, 15),
      );

      // Avança o relógio para 08:05
      clock.setTime(DateTime(2026, 10, 27, 8, 5));

      final next = RecurrenceEngine.getNextOccurrence(
        reminder: snoozedReminder,
        fromDateTime: clock.now(),
      );
      expect(next, equals(DateTime(2026, 10, 27, 8, 15)));

      // Verifica que a lista de próximos disparos inclui o snooze e em seguida a sequência regular (09:00, 10:00, etc.)
      final upcoming = RecurrenceEngine.getUpcomingOccurrences(
        reminder: snoozedReminder,
        fromDateTime: clock.now(),
        limit: 4,
      );

      expect(upcoming.length, equals(4));
      expect(upcoming[0], equals(DateTime(2026, 10, 27, 8, 15))); // Snooze
      expect(upcoming[1], equals(DateTime(2026, 10, 27, 9, 0))); // Regular
      expect(upcoming[2], equals(DateTime(2026, 10, 27, 10, 0))); // Regular
      expect(upcoming[3], equals(DateTime(2026, 10, 27, 11, 0))); // Regular
    });

    // 12. Mudança de data ou horário do sistema
    test('Cenário 12: Mudança de data ou horário do sistema reavalia corretamente', () {
      final clock = SettableClock(DateTime(2026, 10, 27, 9, 15));
      final reminder = Reminder(
        id: 'rem-12',
        title: 'Água',
        startHour: 8,
        startMinute: 0,
        endHour: 18,
        endMinute: 0,
        intervalMinutes: 60,
        selectedDays: {DateTime.tuesday},
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      // Às 09:15, o próximo é 10:00
      final next1 = RecurrenceEngine.getNextOccurrence(
        reminder: reminder,
        fromDateTime: clock.now(),
      );
      expect(next1, equals(DateTime(2026, 10, 27, 10, 0)));

      // O relógio do sistema pula 3 horas para 12:30
      clock.setTime(DateTime(2026, 10, 27, 12, 30));

      // Reavaliação imediata: próximo é 13:00 (não fica travado no passado)
      final next2 = RecurrenceEngine.getNextOccurrence(
        reminder: reminder,
        fromDateTime: clock.now(),
      );
      expect(next2, equals(DateTime(2026, 10, 27, 13, 0)));
    });

    // 13. Reconstrução dos agendamentos após reinicialização
    test('Cenário 13: Reconstrução determinística dos agendamentos após reboot', () {
      final clock = SettableClock(DateTime(2026, 10, 27, 14, 05));

      final persistedReminders = [
        Reminder(
          id: 'rem-reboot-1',
          title: 'Hidratação',
          startHour: 8,
          startMinute: 0,
          endHour: 18,
          endMinute: 0,
          intervalMinutes: 60,
          selectedDays: {DateTime.tuesday},
          createdAt: DateTime(2026, 10, 26),
          updatedAt: DateTime(2026, 10, 26),
        ),
        Reminder(
          id: 'rem-reboot-2',
          title: 'Descanso visual',
          startHour: 9,
          startMinute: 0,
          endHour: 17,
          endMinute: 0,
          intervalMinutes: 30,
          selectedDays: {DateTime.tuesday},
          createdAt: DateTime(2026, 10, 26),
          updatedAt: DateTime(2026, 10, 26),
        ),
      ];

      // Reconstrução: obtém os próximos disparos a partir da hora atual pós-boot
      final nextMap = <String, DateTime?>{};
      for (final r in persistedReminders) {
        nextMap[r.id] = RecurrenceEngine.getNextOccurrence(
          reminder: r,
          fromDateTime: clock.now(),
        );
      }

      expect(nextMap['rem-reboot-1'], equals(DateTime(2026, 10, 27, 15, 0)));
      expect(nextMap['rem-reboot-2'], equals(DateTime(2026, 10, 27, 14, 30)));
    });

    // 14. Validação de horários e intervalos inválidos
    test('Cenário 14: Validação de horários e intervalos inválidos', () {
      // Horário final igual ao inicial
      final res1 = RecurrenceValidator.validateTimeWindow(
        startHour: 10,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
      );
      expect(res1.isValid, isFalse);

      // Horário final anterior ao inicial (cruzando meia-noite)
      final res2 = RecurrenceValidator.validateTimeWindow(
        startHour: 22,
        startMinute: 0,
        endHour: 6,
        endMinute: 0,
      );
      expect(res2.isValid, isFalse);

      // Intervalo zero ou negativo
      expect(RecurrenceValidator.validateInterval(0).isValid, isFalse);
      expect(RecurrenceValidator.validateInterval(-15).isValid, isFalse);
      expect(RecurrenceValidator.validateInterval(30).isValid, isTrue);

      // Dias da semana vazios
      expect(RecurrenceValidator.validateSelectedDays({}).isValid, isFalse);
      expect(RecurrenceValidator.validateSelectedDays({1, 3, 5}).isValid, isTrue);

      // Título vazio
      expect(RecurrenceValidator.validateTitle('').isValid, isFalse);
      expect(RecurrenceValidator.validateTitle('   ').isValid, isFalse);
      expect(RecurrenceValidator.validateTitle('Beber água').isValid, isTrue);
    });
  });
}
