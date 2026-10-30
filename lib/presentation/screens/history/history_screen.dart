import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/time_formatters.dart';
import '../../../domain/entities/reminder_log.dart';
import '../../providers/app_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  ReminderLogStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(historyStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Eventos'),
        actions: [
          IconButton(
            tooltip: 'Limpar histórico',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _confirmClearHistory(context),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (logs) {
          final filteredLogs = _selectedStatus == null
              ? logs
              : logs.where((l) => l.status == _selectedStatus).toList();

          return Column(
            children: [
              // Barra de Filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('Todos (${logs.length})'),
                      selected: _selectedStatus == null,
                      onSelected: (_) =>
                          setState(() => _selectedStatus = null),
                    ),
                    const SizedBox(width: 8),
                    ...ReminderLogStatus.values.map((status) {
                      final count =
                          logs.where((l) => l.status == status).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${status.label} ($count)'),
                          selected: _selectedStatus == status,
                          onSelected: (_) =>
                              setState(() => _selectedStatus = status),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum evento registrado no histórico.',
                              style: TextStyle(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return _buildLogCard(log, theme);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Widget _buildLogCard(ReminderLog log, ThemeData theme) {
    Color badgeColor;
    IconData badgeIcon;

    switch (log.status) {
      case ReminderLogStatus.completed:
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle_rounded;
        break;
      case ReminderLogStatus.delivered:
        badgeColor = theme.colorScheme.primary;
        badgeIcon = Icons.notifications_active_rounded;
        break;
      case ReminderLogStatus.snoozed:
        badgeColor = Colors.amber.shade800;
        badgeIcon = Icons.snooze_rounded;
        break;
      case ReminderLogStatus.dismissed:
        badgeColor = Colors.red.shade400;
        badgeIcon = Icons.cancel_rounded;
        break;
      case ReminderLogStatus.scheduled:
        badgeColor = Colors.blue;
        badgeIcon = Icons.schedule_rounded;
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor.withValues(alpha: 0.15),
          child: Icon(badgeIcon, color: badgeColor, size: 20),
        ),
        title: Text(
          log.reminderTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'Programado: ${TimeFormatters.formatDateTime(log.scheduledTime)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (log.processedTime != null)
              Text(
                'Processado: ${TimeFormatters.formatDateTime(log.processedTime!)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            if (log.note != null && log.note!.isNotEmpty)
              Text(
                'Nota: ${log.note}',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            log.status.label,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Histórico'),
        content: const Text(
            'Deseja apagar todos os registros do histórico de disparos? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(historyRepositoryProvider).clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Histórico limpo com sucesso!')),
        );
      }
    }
  }
}
