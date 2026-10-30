import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lembrol/core/clock.dart';
import 'package:lembrol/domain/entities/app_settings.dart';
import 'package:lembrol/domain/entities/reminder.dart';
import 'package:lembrol/domain/entities/reminder_log.dart';
import 'package:lembrol/domain/repositories/history_repository.dart';
import 'package:lembrol/domain/repositories/reminder_repository.dart';
import 'package:lembrol/domain/repositories/settings_repository.dart';
import 'package:lembrol/platform/notifications/notification_service.dart';
import 'package:lembrol/presentation/providers/app_providers.dart';
import 'package:lembrol/presentation/screens/reminders/reminder_form_screen.dart';

class FakeReminderRepository implements ReminderRepository {
  final List<Reminder> _reminders;
  final _controller = StreamController<List<Reminder>>.broadcast();

  FakeReminderRepository([List<Reminder>? initial])
      : _reminders = initial != null ? List.from(initial) : [] {
    _controller.add(_reminders);
  }

  @override
  Stream<List<Reminder>> watchAllReminders() => _controller.stream;

  @override
  Future<List<Reminder>> getAllReminders() async => List.unmodifiable(_reminders);

  @override
  Future<Reminder?> getReminderById(String id) async {
    for (final r in _reminders) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    _reminders.removeWhere((r) => r.id == reminder.id);
    _reminders.add(reminder);
    _controller.add(List.unmodifiable(_reminders));
  }

  @override
  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    _controller.add(List.unmodifiable(_reminders));
  }

  @override
  Future<void> toggleReminderActive(String id, bool isActive) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(isActive: isActive);
      _controller.add(List.unmodifiable(_reminders));
    }
  }

  @override
  Future<void> setSnooze(String id, DateTime? snoozeUntil) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(snoozeUntil: snoozeUntil);
      _controller.add(List.unmodifiable(_reminders));
    }
  }
}

class FakeHistoryRepository implements HistoryRepository {
  final List<ReminderLog> _logs = [];
  final _controller = StreamController<List<ReminderLog>>.broadcast();

  @override
  Stream<List<ReminderLog>> watchAllLogs() => _controller.stream;
  @override
  Future<List<ReminderLog>> getAllLogs() async => List.unmodifiable(_logs);
  @override
  Future<void> addLog(ReminderLog log) async {
    _logs.add(log);
    _controller.add(List.unmodifiable(_logs));
  }
  @override
  Future<void> updateLog(ReminderLog log) async {
    final idx = _logs.indexWhere((l) => l.id == log.id);
    if (idx != -1) _logs[idx] = log;
    _controller.add(List.unmodifiable(_logs));
  }
  @override
  Future<void> clearHistory() async {
    _logs.clear();
    _controller.add([]);
  }
  @override
  Future<void> deleteLogsForReminder(String reminderId) async {
    _logs.removeWhere((l) => l.reminderId == reminderId);
    _controller.add(List.unmodifiable(_logs));
  }
}

class FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();
  final _controller = StreamController<AppSettings>.broadcast();

  @override
  Stream<AppSettings> watchSettings() => _controller.stream;
  @override
  Future<AppSettings> getSettings() async => _settings;
  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    _controller.add(_settings);
  }
}

class FakeNotificationService implements NotificationService {
  @override
  Future<void> initialize({
    void Function(String reminderId, String? action)? onNotificationAction,
  }) async {}
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<bool> hasNotificationPermissions() async => true;
  @override
  Future<bool> canScheduleExactAlarms() async => true;
  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    bool sound = true,
    bool vibration = true,
    String? payload,
  }) async {}
  @override
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    String? body,
    bool sound = true,
    bool vibration = true,
    String? payload,
  }) async {}
  @override
  Future<void> cancelNotification(int id) async {}
  @override
  Future<void> cancelAllNotifications() async {}
}

void main() {
  late FakeReminderRepository fakeReminderRepo;
  late FakeHistoryRepository fakeHistoryRepo;
  late FakeSettingsRepository fakeSettingsRepo;
  late FakeNotificationService fakeNotifService;
  late SettableClock controllableClock;

  setUp(() {
    controllableClock = SettableClock(DateTime(2026, 10, 27, 8, 0));
    fakeReminderRepo = FakeReminderRepository();
    fakeHistoryRepo = FakeHistoryRepository();
    fakeSettingsRepo = FakeSettingsRepository();
    fakeNotifService = FakeNotificationService();
  });

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(controllableClock),
        reminderRepositoryProvider.overrideWithValue(fakeReminderRepo),
        historyRepositoryProvider.overrideWithValue(fakeHistoryRepo),
        settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
        notificationServiceProvider.overrideWithValue(fakeNotifService),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Testes de Widget - ReminderFormScreen', () {
    testWidgets('Renderiza tela de cadastro com campos essenciais e prévia', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(const ReminderFormScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Novo Lembrete'), findsOneWidget);
      expect(find.text('Título do lembrete *'), findsOneWidget);
      expect(find.text('Repetir a cada (minutos) *'), findsOneWidget);
      expect(find.text('Janela de Horários'), findsOneWidget);
      expect(find.text('Dias da Semana'), findsOneWidget);
      expect(find.text('Prévia dos Próximos Disparos'), findsOneWidget);
    });

    testWidgets('Validação: Título vazio impede salvamento e exibe erro', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(const ReminderFormScreen()));
      await tester.pumpAndSettle();

      final saveBtn = find.text('Salvar');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('O título do lembrete é obrigatório.'), findsOneWidget);
    });

    testWidgets('Validação: Intervalo inválido impede salvamento e exibe erro', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(const ReminderFormScreen()));
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextFormField, 'Título do lembrete *');
      await tester.enterText(titleField, 'Pausa para café');

      final intervalField = find.widgetWithText(TextFormField, 'Repetir a cada (minutos) *');
      await tester.enterText(intervalField, '0');

      final saveBtn = find.text('Salvar');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('O intervalo deve ser um número inteiro positivo em minutos.'),
        findsOneWidget,
      );
    });

    testWidgets('Interação com seleção de dias e atalhos rápidos', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(const ReminderFormScreen()));
      await tester.pumpAndSettle();

      final weekendShortcut = find.text('Fim de sem.');
      expect(weekendShortcut, findsOneWidget);
      await tester.tap(weekendShortcut);
      await tester.pumpAndSettle();

      final allShortcut = find.text('Todos');
      expect(allShortcut, findsOneWidget);
      await tester.tap(allShortcut);
      await tester.pumpAndSettle();

      final chip30m = find.text('30 min');
      expect(chip30m, findsOneWidget);
      await tester.tap(chip30m);
      await tester.pumpAndSettle();

      final intervalFinder = find.widgetWithText(TextFormField, 'Repetir a cada (minutos) *');
      final formField = tester.widget<TextFormField>(intervalFinder);
      expect(formField.controller?.text, equals('30'));
    });

    testWidgets('Modo de Edição carrega dados do lembrete existente', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final existing = Reminder(
        id: 'rem-edit-1',
        title: 'Alongar Coluna',
        description: 'Fazer 5 repetições',
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        intervalMinutes: 45,
        selectedDays: {1, 2, 3},
        category: 'Postura e Ergonomia',
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );
      await fakeReminderRepo.saveReminder(existing);

      await tester.pumpWidget(
        createWidgetUnderTest(
          const ReminderFormScreen(reminderId: 'rem-edit-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar Lembrete'), findsOneWidget);
      expect(find.text('Alongar Coluna'), findsOneWidget);
      expect(find.text('Fazer 5 repetições'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
    });
  });
}
