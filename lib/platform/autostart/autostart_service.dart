import 'dart:io';
import 'package:flutter/foundation.dart';

class AutostartService {
  static const String _registryValueName = 'Lembrol';
  static const String _registryKey =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';

  /// Verifica se o aplicativo está configurado para inicialização automática no Windows
  static Future<bool> isEnabled() async {
    if (kIsWeb || !Platform.isWindows) return false;

    try {
      final result = await Process.run('reg', [
        'query',
        _registryKey,
        '/v',
        _registryValueName,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Erro ao consultar registro do Windows para autostart: $e');
      return false;
    }
  }

  /// Ativa ou desativa a inicialização automática no Windows
  static Future<bool> setEnabled(bool enable) async {
    if (kIsWeb || !Platform.isWindows) return false;

    try {
      if (enable) {
        final exePath = Platform.resolvedExecutable;
        final result = await Process.run('reg', [
          'add',
          _registryKey,
          '/v',
          _registryValueName,
          '/t',
          'REG_SZ',
          '/d',
          '"$exePath"',
          '/f',
        ]);
        return result.exitCode == 0;
      } else {
        final result = await Process.run('reg', [
          'delete',
          _registryKey,
          '/v',
          _registryValueName,
          '/f',
        ]);
        return result.exitCode == 0;
      }
    } catch (e) {
      debugPrint('Erro ao atualizar autostart no registro do Windows: $e');
      return false;
    }
  }
}
