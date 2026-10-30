import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/clock.dart';
import '../../data/datasources/database.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_log.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../platform/notifications/local_notification_service.dart';
import '../../platform/notifications/notification_service.dart';
import '../../platform/permissions/permission_manager.dart';
import '../../platform/scheduler/reminder_scheduler_service.dart';

// --- Dependências Fundamentais ---

final clockProvider = Provider<AppClock>((ref) {
  return const SystemClock();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ReminderRepositoryImpl(db);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HistoryRepositoryImpl(db);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepositoryImpl(db);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

final permissionManagerProvider = Provider<PermissionManager>((ref) {
  final notif = ref.watch(notificationServiceProvider);
  return PermissionManager(notif);
});

final schedulerServiceProvider = Provider<ReminderSchedulerService>((ref) {
  final service = ReminderSchedulerService(
    reminderRepository: ref.watch(reminderRepositoryProvider),
    historyRepository: ref.watch(historyRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

// --- Streams Reativas para a UI ---

final remindersStreamProvider = StreamProvider<List<Reminder>>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.watchAllReminders();
});

final historyStreamProvider = StreamProvider<List<ReminderLog>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.watchAllLogs();
});

final settingsStreamProvider = StreamProvider<AppSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSettings();
});

final diagnosticsProvider = FutureProvider<SystemDiagnostics>((ref) async {
  final manager = ref.watch(permissionManagerProvider);
  return manager.runDiagnostics();
});

final nextUpcomingProvider = StreamProvider<ScheduledReminderItem?>((ref) {
  final scheduler = ref.watch(schedulerServiceProvider);
  return scheduler.nextUpcomingStream;
});
