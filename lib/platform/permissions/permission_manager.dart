import 'dart:io';
import 'package:flutter/foundation.dart';
import '../notifications/notification_service.dart';

class SystemDiagnostics {
  final bool hasNotificationPermission;
  final bool canScheduleExactAlarms;
  final String platformDescription;
  final List<String> warnings;

  const SystemDiagnostics({
    required this.hasNotificationPermission,
    required this.canScheduleExactAlarms,
    required this.platformDescription,
    required this.warnings,
  });

  bool get isHealthy =>
      hasNotificationPermission && canScheduleExactAlarms && warnings.isEmpty;
}

class PermissionManager {
  final NotificationService _notificationService;

  PermissionManager(this._notificationService);

  Future<SystemDiagnostics> runDiagnostics() async {
    final warnings = <String>[];
    bool notifPerm = true;
    bool exactPerm = true;
    String platformDesc = 'Plataforma Desktop';

    if (kIsWeb) {
      platformDesc = 'Navegador Web';
      warnings.add('Execução em Web possui limitações para alarmes em background.');
    } else if (Platform.isAndroid) {
      platformDesc = 'Android Mobile';
      notifPerm = await _notificationService.hasNotificationPermissions();
      exactPerm = await _notificationService.canScheduleExactAlarms();

      if (!notifPerm) {
        warnings.add(
            'Permissão de notificações desativada. O Lembrol não conseguirá alertar.');
      }
      if (!exactPerm) {
        warnings.add(
            'Permissão de alarmes exatos não concedida. Os avisos podem sofrer atraso pelo sistema.');
      }
    } else if (Platform.isWindows) {
      platformDesc = 'Windows Desktop';
      notifPerm = true;
      exactPerm = true;
    }

    return SystemDiagnostics(
      hasNotificationPermission: notifPerm,
      canScheduleExactAlarms: exactPerm,
      platformDescription: platformDesc,
      warnings: warnings,
    );
  }

  Future<bool> requestAllPermissions() async {
    return _notificationService.requestPermissions();
  }
}
