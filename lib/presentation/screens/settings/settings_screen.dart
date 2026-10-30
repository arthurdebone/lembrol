import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../platform/autostart/autostart_service.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isWindowsAutostartEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkWindowsAutostart();
  }

  Future<void> _checkWindowsAutostart() async {
    if (!kIsWeb && Platform.isWindows) {
      final enabled = await AutostartService.isEnabled();
      if (mounted) setState(() => _isWindowsAutostartEnabled = enabled);
    }
  }

  Future<void> _toggleWindowsAutostart(bool enable) async {
    final success = await AutostartService.setEnabled(enable);
    if (success && mounted) {
      setState(() => _isWindowsAutostartEnabled = enable);
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      await ref
          .read(settingsRepositoryProvider)
          .saveSettings(settings.copyWith(autostartOnWindows: enable));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final diagnosticsAsync = ref.watch(diagnosticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações & Diagnóstico'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Seção Aparência
              _buildSectionHeader('Aparência e Tema', Icons.palette_outlined),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tema do Aplicativo'),
                        subtitle: Text(_getThemeLabel(settings.themeMode)),
                        trailing: DropdownButton<ThemeMode>(
                          value: settings.themeMode,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('Padrão do Sistema'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Claro'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Escuro'),
                            ),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              ref.read(settingsRepositoryProvider).saveSettings(
                                    settings.copyWith(themeMode: mode),
                                  );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Seção Preferências de Alerta
              _buildSectionHeader('Padrões de Notificação', Icons.notifications_active_outlined),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tempo padrão para adiamento'),
                        subtitle: Text('${settings.defaultSnoozeMinutes} minutos'),
                        trailing: DropdownButton<int>(
                          value: settings.defaultSnoozeMinutes,
                          underline: const SizedBox.shrink(),
                          items: AppConstants.snoozeDurationsMinutes.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text('$m min'),
                            );
                          }).toList(),
                          onChanged: (m) {
                            if (m != null) {
                              ref.read(settingsRepositoryProvider).saveSettings(
                                    settings.copyWith(defaultSnoozeMinutes: m),
                                  );
                            }
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Som ativado por padrão'),
                        subtitle: const Text('Emite toque sonoro nos novos lembretes'),
                        value: settings.defaultSound,
                        onChanged: (v) {
                          ref.read(settingsRepositoryProvider).saveSettings(
                                settings.copyWith(defaultSound: v),
                              );
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Vibração ativada por padrão'),
                        subtitle: const Text('Para dispositivos móveis suportados'),
                        value: settings.defaultVibration,
                        onChanged: (v) {
                          ref.read(settingsRepositoryProvider).saveSettings(
                                settings.copyWith(defaultVibration: v),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Seção Plataforma e Inicialização
              if (!kIsWeb && Platform.isWindows) ...[
                _buildSectionHeader('Integração com Windows', Icons.desktop_windows_outlined),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Iniciar com o Windows'),
                      subtitle: const Text(
                          'Abre o Lembrol automaticamente ao ligar o computador'),
                      value: _isWindowsAutostartEnabled,
                      onChanged: _toggleWindowsAutostart,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Diagnóstico do Sistema
              _buildSectionHeader('Diagnóstico de Alarmes', Icons.medical_services_outlined),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: diagnosticsAsync.when(
                    data: (diag) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                diag.isHealthy
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_rounded,
                                color: diag.isHealthy ? Colors.green : Colors.amber.shade800,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                diag.isHealthy
                                    ? 'Sistema pronto e configurado'
                                    : 'Atenção necessária',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: diag.isHealthy ? Colors.green : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Ambiente: ${diag.platformDescription}',
                              style: const TextStyle(fontSize: 12)),
                          Text(
                            'Notificações: ${diag.hasNotificationPermission ? "Ativas" : "Bloqueadas"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Alarmes exatos: ${diag.canScheduleExactAlarms ? "Disponíveis" : "Restritos"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (diag.warnings.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...diag.warnings.map(
                              (w) => Text('• $w',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.amber.shade900)),
                            ),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Solicitar / Atualizar Permissões'),
                            onPressed: () async {
                              await ref
                                  .read(permissionManagerProvider)
                                  .requestAllPermissions();
                              ref.invalidate(diagnosticsProvider);
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Erro no diagnóstico: $e'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Backup e Dados Locais
              _buildSectionHeader('Dados Locais e Backup', Icons.storage_rounded),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Todos os dados ficam armazenados exclusivamente no seu dispositivo, sem envio a servidores ou nuvem.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Exportar JSON'),
                            onPressed: () => _exportJsonBackup(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Padrão do Sistema';
      case ThemeMode.light:
        return 'Modo Claro';
      case ThemeMode.dark:
        return 'Modo Escuro';
    }
  }

  Future<void> _exportJsonBackup(BuildContext context) async {
    final reminders = await ref.read(reminderRepositoryProvider).getAllReminders();
    final logs = await ref.read(historyRepositoryProvider).getAllLogs();

    final backupData = {
      'app': 'Lembrol',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'remindersCount': reminders.length,
      'reminders': reminders
          .map((r) => {
                'id': r.id,
                'title': r.title,
                'description': r.description,
                'startHour': r.startHour,
                'startMinute': r.startMinute,
                'endHour': r.endHour,
                'endMinute': r.endMinute,
                'intervalMinutes': r.intervalMinutes,
                'selectedDays': r.selectedDays.toList(),
                'isActive': r.isActive,
                'category': r.category,
              })
          .toList(),
      'logsCount': logs.length,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exportação de Dados'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonString,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }
}
