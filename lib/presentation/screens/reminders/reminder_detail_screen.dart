import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/time_formatters.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/recurrence/recurrence_engine.dart';
import '../../providers/app_providers.dart';

class ReminderDetailScreen extends ConsumerWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final remindersAsync = ref.watch(remindersStreamProvider);
    final clock = ref.watch(clockProvider);

    return remindersAsync.when(
      data: (reminders) {
        final reminder = reminders.where((r) => r.id == reminderId).firstOrNull;

        if (reminder == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lembrete não encontrado')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Este lembrete foi removido.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/reminders'),
                    child: const Text('Voltar à lista'),
                  ),
                ],
              ),
            ),
          );
        }

        final now = clock.now();
        final nextOccurrence = RecurrenceEngine.getNextOccurrence(
          reminder: reminder,
          fromDateTime: now,
        );

        final upcomingList = RecurrenceEngine.getUpcomingOccurrences(
          reminder: reminder,
          fromDateTime: now,
          limit: 8,
        );

        final isSnoozed = reminder.isSnoozedAt(now);

        return Scaffold(
          appBar: AppBar(
            title: Text(reminder.title),
            actions: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/reminders/${reminder.id}/edit'),
              ),
              IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context, ref, reminder),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Card de Status e Próximo Disparo
              Card(
                color: reminder.isActive
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                reminder.isActive
                                    ? Icons.check_circle_rounded
                                    : Icons.pause_circle_rounded,
                                color: reminder.isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reminder.isActive ? 'ATIVO' : 'PAUSADO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: reminder.isActive
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          if (isSnoozed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ADIADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Próximo Disparo:',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextOccurrence != null
                            ? TimeFormatters.formatRelativeDateTime(
                                nextOccurrence, now)
                            : 'Nenhum disparo agendado',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (nextOccurrence != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tempo restante: ${TimeFormatters.formatCountdown(nextOccurrence.difference(now))}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ações Rápidas (Adiar / Concluir / Pausar)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.snooze_rounded, size: 16),
                          label: const Text('Adiar...'),
                          onPressed: () => _showSnoozeOptions(context, ref, reminder.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('Concluir'),
                          onPressed: () async {
                            await ref
                                .read(schedulerServiceProvider)
                                .completeOccurrence(reminder.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Disparo marcado como concluído!')),
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

              // Informações de Configuração
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parâmetros do Lembrete',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Janela ativa:',
                          '${TimeFormatters.formatTimeOfDay(reminder.startTime)} até ${TimeFormatters.formatTimeOfDay(reminder.endTime)}'),
                      _buildInfoRow('Intervalo:',
                          'A cada ${reminder.intervalMinutes} minutos'),
                      _buildInfoRow('Dias:',
                          TimeFormatters.formatSelectedDays(reminder.selectedDays)),
                      if (reminder.category != null)
                        _buildInfoRow('Categoria:', reminder.category!),
                      _buildInfoRow(
                          'Notificação:', reminder.enableVisual ? 'Sim' : 'Não'),
                      _buildInfoRow('Som:', reminder.enableSound ? 'Sim' : 'Não'),
                      _buildInfoRow(
                          'Vibração:', reminder.enableVibration ? 'Sim' : 'Não'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Próximas 8 ocorrências programadas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Próximas Ocorrências',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (upcomingList.isEmpty)
                        const Text(
                          'Nenhuma ocorrência futura no calendário ativo.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...upcomingList.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final date = entry.value;
                          final label =
                              TimeFormatters.formatRelativeDateTime(date, now);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$idx',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  label,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnoozeOptions(
      BuildContext context, WidgetRef ref, String reminderId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adiar disparo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.snooze_rounded),
                  title: const Text('Adiar por 5 minutos'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(schedulerServiceProvider)
                        .snoozeReminder(reminderId, 5);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.snooze_rounded),
                  title: const Text('Adiar por 10 minutos'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(schedulerServiceProvider)
                        .snoozeReminder(reminderId, 10);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.snooze_rounded),
                  title: const Text('Adiar por 15 minutos'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(schedulerServiceProvider)
                        .snoozeReminder(reminderId, 15);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Reminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Lembrete'),
        content: Text('Tem certeza que deseja excluir "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(reminderRepositoryProvider).deleteReminder(reminder.id);
      await ref.read(schedulerServiceProvider).cancelReminder(reminder.id);
      if (context.mounted) {
        context.go('/reminders');
      }
    }
  }
}
