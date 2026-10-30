// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/clock.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_log.dart';
import '../../domain/recurrence/recurrence_engine.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../notifications/notification_service.dart';

class ScheduledReminderItem {
  final Reminder reminder;
  final DateTime nextOccurrence;

  const ScheduledReminderItem({
    required this.reminder,
    required this.nextOccurrence,
  });
}

class ReminderSchedulerService {
  final ReminderRepository _reminderRepository;
  final HistoryRepository _historyRepository;
  final NotificationService _notificationService;
  final AppClock _clock;

  Timer? _tickerTimer;
  final _uuid = const Uuid();

  // Mapeamento em memória dos próximos disparos por reminderId
  final Map<String, DateTime> _nextTriggerCache = {};

  // StreamController para emitir o próximo lembrete mais urgente para o Dashboard
  final _nextUpcomingController =
      StreamController<ScheduledReminderItem?>.broadcast();

  Stream<ScheduledReminderItem?> get nextUpcomingStream =>
      _nextUpcomingController.stream;

  ReminderSchedulerService({
    required ReminderRepository reminderRepository,
    required HistoryRepository historyRepository,
    required NotificationService notificationService,
    AppClock clock = const SystemClock(),
  })  : _reminderRepository = reminderRepository,
        _historyRepository = historyRepository,
        _notificationService = notificationService,
        _clock = clock;

  Future<void> initialize() async {
    await _notificationService.initialize(
      onNotificationAction: handleNotificationAction,
    );

    // Inicia a verificação contínua periódica (a cada segundo) para sincronismo
    _startTicker();

    // Reconstrói a programação a partir dos dados persistidos
    await rescheduleAll();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkPendingTriggers();
    });
  }

  /// Verifica se algum lembrete atingiu o momento de disparo
  Future<void> _checkPendingTriggers() async {
    final now = _clock.now();
    final expiredEntries = <String, DateTime>{};

    for (final entry in _nextTriggerCache.entries) {
      if (entry.value.isBefore(now) || entry.value.isAtSameMomentAs(now)) {
        expiredEntries[entry.key] = entry.value;
      }
    }

    for (final entry in expiredEntries.entries) {
      final reminderId = entry.key;
      final scheduledTime = entry.value;

      _nextTriggerCache.remove(reminderId);

      final reminder = await _reminderRepository.getReminderById(reminderId);
      if (reminder != null && reminder.isActive) {
        await _fireTrigger(reminder, scheduledTime);
      }
    }
  }

  /// Executa o disparo do lembrete, exibindo notificação e registrando no histórico
  Future<void> _fireTrigger(Reminder reminder, DateTime scheduledTime) async {
    final now = _clock.now();
    final notifId = NotificationService.getStableNotificationId(reminder.id);

    // 1. Exibe notificação imediata
    if (reminder.enableVisual) {
      await _notificationService.showImmediateNotification(
        id: notifId,
        title: reminder.title,
        body: reminder.description,
        sound: reminder.enableSound,
        vibration: reminder.enableVibration,
        payload: reminder.id,
      );
    }

    // 2. Registra no histórico como 'delivered' (disparado)
    final log = ReminderLog(
      id: _uuid.v4(),
      reminderId: reminder.id,
      reminderTitle: reminder.title,
      scheduledTime: scheduledTime,
      processedTime: now,
      status: ReminderLogStatus.delivered,
      createdAt: now,
    );
    await _historyRepository.addLog(log);

    // 3. Se havia um snooze ativo consumido neste disparo, limpa o snooze
    if (reminder.snoozeUntil != null &&
        (reminder.snoozeUntil!.isBefore(now) ||
            reminder.snoozeUntil!.isAtSameMomentAs(now))) {
      await _reminderRepository.setSnooze(reminder.id, null);
    }

    // 4. Calcula e agenda a próxima ocorrência
    final updatedReminder =
        await _reminderRepository.getReminderById(reminder.id);
    if (updatedReminder != null && updatedReminder.isActive) {
      await scheduleNextForReminder(updatedReminder);
    }

    _emitNextUpcoming();
  }

  /// Reavalia e reagenda todos os lembretes ativos (útil após reboot ou alteração de relógio)
  Future<void> rescheduleAll() async {
    _nextTriggerCache.clear();
    await _notificationService.cancelAllNotifications();

    final reminders = await _reminderRepository.getAllReminders();
    for (final reminder in reminders) {
      if (reminder.isActive) {
        await scheduleNextForReminder(reminder);
      }
    }

    _emitNextUpcoming();
  }

  /// Calcula o próximo disparo de um lembrete e registra no OS
  Future<void> scheduleNextForReminder(Reminder reminder) async {
    final notifId = NotificationService.getStableNotificationId(reminder.id);
    await _notificationService.cancelNotification(notifId);

    if (!reminder.isActive) {
      _nextTriggerCache.remove(reminder.id);
      _emitNextUpcoming();
      return;
    }

    final now = _clock.now();
    final nextOccurrence = RecurrenceEngine.getNextOccurrence(
      reminder: reminder,
      fromDateTime: now,
    );

    if (nextOccurrence != null) {
      _nextTriggerCache[reminder.id] = nextOccurrence;

      // Agenda no sistema operacional (Android AlarmManager / Windows ScheduledToast)
      if (reminder.enableVisual) {
        await _notificationService.scheduleNotification(
          id: notifId,
          title: reminder.title,
          body: reminder.description,
          scheduledDate: nextOccurrence,
          sound: reminder.enableSound,
          vibration: reminder.enableVibration,
          payload: reminder.id,
        );
      }
    } else {
      _nextTriggerCache.remove(reminder.id);
    }

    _emitNextUpcoming();
  }

  /// Cancela os agendamentos associados a um lembrete
  Future<void> cancelReminder(String reminderId) async {
    final notifId = NotificationService.getStableNotificationId(reminderId);
    await _notificationService.cancelNotification(notifId);
    _nextTriggerCache.remove(reminderId);
    _emitNextUpcoming();
  }

  /// Adia a ocorrência atual por X minutos sem alterar a sequência regular
  Future<void> snoozeReminder(String reminderId, int minutes) async {
    final reminder = await _reminderRepository.getReminderById(reminderId);
    if (reminder == null) return;

    final now = _clock.now();
    final snoozeTarget = now.add(Duration(minutes: minutes));

    // Salva o adiamento na persistência
    await _reminderRepository.setSnooze(reminderId, snoozeTarget);

    // Registra no histórico que o usuário adiou
    final log = ReminderLog(
      id: _uuid.v4(),
      reminderId: reminder.id,
      reminderTitle: reminder.title,
      scheduledTime: now,
      processedTime: now,
      status: ReminderLogStatus.snoozed,
      userAction: 'snooze_${minutes}m',
      note: 'Adiado por $minutes minutos',
      createdAt: now,
    );
    await _historyRepository.addLog(log);

    // Atualiza o agendamento
    final updated = reminder.copyWith(snoozeUntil: snoozeTarget);
    await scheduleNextForReminder(updated);
  }

  /// Conclui manualmente a ocorrência atual
  Future<void> completeOccurrence(String reminderId) async {
    final reminder = await _reminderRepository.getReminderById(reminderId);
    if (reminder == null) return;

    final now = _clock.now();

    // Se estava em snooze, remove
    if (reminder.snoozeUntil != null) {
      await _reminderRepository.setSnooze(reminderId, null);
    }

    // Registra conclusão
    final log = ReminderLog(
      id: _uuid.v4(),
      reminderId: reminder.id,
      reminderTitle: reminder.title,
      scheduledTime: now,
      processedTime: now,
      status: ReminderLogStatus.completed,
      userAction: 'completed',
      note: 'Confirmado pelo usuário',
      createdAt: now,
    );
    await _historyRepository.addLog(log);

    final updated = reminder.copyWith(clearSnooze: true);
    await scheduleNextForReminder(updated);
  }

  /// Processa ações acionadas a partir dos botões da notificação
  Future<void> handleNotificationAction(String reminderId, String? action) async {
    if (action == 'completed') {
      await completeOccurrence(reminderId);
    } else if (action == 'snooze_10m') {
      await snoozeReminder(reminderId, 10);
    } else if (action == 'snooze_5m') {
      await snoozeReminder(reminderId, 5);
    } else if (action == 'snooze_15m') {
      await snoozeReminder(reminderId, 15);
    }
  }

  /// Retorna o próximo lembrete mais urgente e seu horário
  ScheduledReminderItem? getNextUpcomingItem(List<Reminder> reminders) {
    if (_nextTriggerCache.isEmpty) return null;

    final reminderMap = {for (final r in reminders) r.id: r};
    ScheduledReminderItem? earliest;

    for (final entry in _nextTriggerCache.entries) {
      final reminder = reminderMap[entry.key];
      if (reminder != null && reminder.isActive) {
        if (earliest == null || entry.value.isBefore(earliest.nextOccurrence)) {
          earliest = ScheduledReminderItem(
            reminder: reminder,
            nextOccurrence: entry.value,
          );
        }
      }
    }

    return earliest;
  }

  void _emitNextUpcoming() async {
    final reminders = await _reminderRepository.getAllReminders();
    final next = getNextUpcomingItem(reminders);
    if (!_nextUpcomingController.isClosed) {
      _nextUpcomingController.add(next);
    }
  }

  void dispose() {
    _tickerTimer?.cancel();
    _nextUpcomingController.close();
  }
}
