import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/constants/app_constants.dart';
import 'notification_service.dart';

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  void Function(String reminderId, String? action)? _actionCallback;

  @override
  Future<void> initialize({
    void Function(String reminderId, String? action)? onNotificationAction,
  }) async {
    if (_isInitialized) return;
    _actionCallback = onNotificationAction;

    tz.initializeTimeZones();

    if (!kIsWeb && Platform.isWindows) {
      try {
        await localNotifier.setup(
          appName: AppConstants.appName,
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
      } catch (e) {
        debugPrint('Erro ao inicializar localNotifier no Windows: $e');
      }
    }

    if (!kIsWeb && Platform.isAndroid) {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );
    }

    _isInitialized = true;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final actionId = response.actionId;
      _actionCallback?.call(payload, actionId);
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final notifGranted =
            await androidImpl.requestNotificationsPermission() ?? false;
        final exactGranted =
            await androidImpl.requestExactAlarmsPermission() ?? false;
        return notifGranted && exactGranted;
      }
    }
    return true;
  }

  @override
  Future<bool> hasNotificationPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.areNotificationsEnabled() ?? false;
      }
    }
    return true;
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.canScheduleExactNotifications() ?? false;
      }
    }
    return true;
  }

  NotificationDetails _buildAndroidDetails({
    required bool sound,
    required bool vibration,
  }) {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: sound,
      enableVibration: vibration,
      actions: const [
        AndroidNotificationAction(
          'completed',
          'Concluir',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'snooze_10m',
          'Adiar 10m',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    return NotificationDetails(android: androidDetails);
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    bool sound = true,
    bool vibration = true,
    String? payload,
  }) async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      final details = _buildAndroidDetails(sound: sound, vibration: vibration);
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body ?? '',
          tzScheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e) {
        debugPrint('Erro ao agendar notificação no Android id $id: $e');
      }
    }
    // No Windows, o PrecisionTimerQueue do ReminderSchedulerService
    // despacha a notificação no momento exato via showImmediateNotification
  }

  @override
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    String? body,
    bool sound = true,
    bool vibration = true,
    String? payload,
  }) async {
    if (kIsWeb) return;

    if (Platform.isWindows) {
      try {
        final notification = LocalNotification(
          identifier: id.toString(),
          title: title,
          body: body ?? '',
          silent: !sound,
          actions: [
            LocalNotificationAction(text: 'Concluir'),
            LocalNotificationAction(text: 'Adiar 10m'),
          ],
        );

        notification.onClick = () {
          _actionCallback?.call(payload ?? '', null);
        };

        notification.onClickAction = (actionIndex) {
          if (actionIndex == 0) {
            _actionCallback?.call(payload ?? '', 'completed');
          } else if (actionIndex == 1) {
            _actionCallback?.call(payload ?? '', 'snooze_10m');
          }
        };

        await notification.show();
      } catch (e) {
        debugPrint('Erro ao disparar notificação local_notifier no Windows: $e');
      }
      return;
    }

    if (Platform.isAndroid) {
      final details = _buildAndroidDetails(sound: sound, vibration: vibration);
      try {
        await _notificationsPlugin.show(
          id,
          title,
          body ?? '',
          details,
          payload: payload,
        );
      } catch (e) {
        debugPrint('Erro ao disparar notificação imediata Android: $e');
      }
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      try {
        await _notificationsPlugin.cancel(id);
      } catch (e) {
        debugPrint('Erro ao cancelar notificação Android id $id: $e');
      }
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      try {
        await _notificationsPlugin.cancelAll();
      } catch (e) {
        debugPrint('Erro ao cancelar todas as notificações Android: $e');
      }
    }
  }
}
