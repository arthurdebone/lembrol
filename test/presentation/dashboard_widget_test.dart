import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lembrol/core/clock.dart';
import 'package:lembrol/domain/entities/reminder.dart';
import 'package:lembrol/platform/permissions/permission_manager.dart';
import 'package:lembrol/presentation/providers/app_providers.dart';
import 'package:lembrol/presentation/screens/dashboard/dashboard_screen.dart';
import 'reminder_form_widget_test.dart';

void main() {
  late FakeReminderRepository fakeReminderRepo;
  late FakeHistoryRepository fakeHistoryRepo;
  late FakeSettingsRepository fakeSettingsRepo;
  late FakeNotificationService fakeNotifService;
  late SettableClock controllableClock;

  setUp(() {
    controllableClock = SettableClock(DateTime(2026, 10, 27, 8, 30));
    fakeReminderRepo = FakeReminderRepository();
    fakeHistoryRepo = FakeHistoryRepository();
    fakeSettingsRepo = FakeSettingsRepository();
    fakeNotifService = FakeNotificationService();
  });

  group('Testes de Widget - DashboardScreen', () {
    testWidgets('Exibe estado vazio acolhedor quando não há lembretes', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(controllableClock),
            reminderRepositoryProvider.overrideWithValue(fakeReminderRepo),
            historyRepositoryProvider.overrideWithValue(fakeHistoryRepo),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            notificationServiceProvider.overrideWithValue(fakeNotifService),
            remindersStreamProvider.overrideWith((ref) => Stream.value(<Reminder>[])),
            diagnosticsProvider.overrideWith(
              (ref) => Future.value(
                const SystemDiagnostics(
                  hasNotificationPermission: true,
                  canScheduleExactAlarms: true,
                  platformDescription: 'Test',
                  warnings: [],
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Seu dia sem esquecimentos'), findsOneWidget);
      expect(find.text('Criar Lembrete'), findsOneWidget);
      expect(find.text('Usar um Modelo'), findsOneWidget);
    });

    testWidgets('Exibe lembretes cadastrados no dashboard', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final reminder = Reminder(
        id: 'rem-dash-1',
        title: 'Beber 300ml de água',
        startHour: 8,
        startMinute: 0,
        endHour: 18,
        endMinute: 0,
        intervalMinutes: 60,
        selectedDays: {DateTime.tuesday}, // Hoje é terça
        isActive: true,
        createdAt: DateTime(2026, 10, 26),
        updatedAt: DateTime(2026, 10, 26),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(controllableClock),
            reminderRepositoryProvider.overrideWithValue(fakeReminderRepo),
            historyRepositoryProvider.overrideWithValue(fakeHistoryRepo),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            notificationServiceProvider.overrideWithValue(fakeNotifService),
            remindersStreamProvider.overrideWith((ref) => Stream.value([reminder])),
            diagnosticsProvider.overrideWith(
              (ref) => Future.value(
                const SystemDiagnostics(
                  hasNotificationPermission: true,
                  canScheduleExactAlarms: true,
                  platformDescription: 'Test',
                  warnings: [],
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Beber 300ml de água'), findsWidgets);
      expect(find.text('Lembretes Ativos (1)'), findsOneWidget);
    });
  });
}
