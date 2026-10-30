import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/time_formatters.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/recurrence/recurrence_engine.dart';
import '../../providers/app_providers.dart';

enum ReminderFilter { all, active, paused }

class ReminderListScreen extends ConsumerStatefulWidget {
  const ReminderListScreen({super.key});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  ReminderFilter _filter = ReminderFilter.all;
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remindersAsync = ref.watch(remindersStreamProvider);
    final clock = ref.watch(clockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Lembretes'),
        actions: [
          IconButton(
            tooltip: 'Novo Lembrete',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/reminders/create'),
          ),
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          final filteredReminders = reminders.where((r) {
            switch (_filter) {
              case ReminderFilter.all:
                return true;
              case ReminderFilter.active:
                return r.isActive;
              case ReminderFilter.paused:
                return !r.isActive;
            }
          }).toList();

          return Column(
            children: [
              // Barra de filtros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('Todos (${reminders.length})'),
                      selected: _filter == ReminderFilter.all,
                      onSelected: (_) =>
                          setState(() => _filter = ReminderFilter.all),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(
                        'Ativos (${reminders.where((r) => r.isActive).length})',
                      ),
                      selected: _filter == ReminderFilter.active,
                      onSelected: (_) =>
                          setState(() => _filter = ReminderFilter.active),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(
                        'Pausados (${reminders.where((r) => !r.isActive).length})',
                      ),
                      selected: _filter == ReminderFilter.paused,
                      onSelected: (_) =>
                          setState(() => _filter = ReminderFilter.paused),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredReminders.isEmpty
                    ? Center(
                        child: Text(
                          _filter == ReminderFilter.all
                              ? 'Nenhum lembrete cadastrado.'
                              : 'Nenhum lembrete nesta categoria.',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredReminders.length,
                        itemBuilder: (context, index) {
                          final reminder = filteredReminders[index];
                          return _buildReminderCard(
                              reminder, clock.now(), theme);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/reminders/create'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildReminderCard(
    Reminder reminder,
    DateTime now,
    ThemeData theme,
  ) {
    final nextOccurrence = RecurrenceEngine.getNextOccurrence(
      reminder: reminder,
      fromDateTime: now,
    );
    final nextTimeStr = nextOccurrence != null
        ? TimeFormatters.formatRelativeDateTime(nextOccurrence, now)
        : 'Inativo ou sem horários';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/reminders/${reminder.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: reminder.isActive
                                ? null
                                : TextDecoration.lineThrough,
                            color: reminder.isActive
                                ? null
                                : theme.colorScheme.outline,
                          ),
                        ),
                        if (reminder.description != null &&
                            reminder.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            reminder.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Switch(
                    value: reminder.isActive,
                    onChanged: (val) async {
                      await ref
                          .read(reminderRepositoryProvider)
                          .toggleReminderActive(reminder.id, val);
                      final updated = reminder.copyWith(isActive: val);
                      await ref
                          .read(schedulerServiceProvider)
                          .scheduleNextForReminder(updated);
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleAction(action, reminder),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Duplicar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: -4),
                    avatar: const Icon(Icons.schedule, size: 14),
                    label: Text(
                      '${TimeFormatters.formatTimeOfDay(reminder.startTime)} - ${TimeFormatters.formatTimeOfDay(reminder.endTime)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Chip(
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: -4),
                    avatar: const Icon(Icons.repeat, size: 14),
                    label: Text(
                      'A cada ${reminder.intervalMinutes} min',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Chip(
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: -4),
                    avatar: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                      TimeFormatters.formatSelectedDays(reminder.selectedDays),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 14,
                    color: reminder.isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Próximo disparo: $nextTimeStr',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: reminder.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(String action, Reminder reminder) async {
    switch (action) {
      case 'edit':
        context.push('/reminders/${reminder.id}/edit');
        break;
      case 'duplicate':
        final now = DateTime.now();
        final duplicate = reminder.copyWith(
          id: _uuid.v4(),
          title: '${reminder.title} (Cópia)',
          createdAt: now,
          updatedAt: now,
          clearSnooze: true,
        );
        await ref.read(reminderRepositoryProvider).saveReminder(duplicate);
        await ref
            .read(schedulerServiceProvider)
            .scheduleNextForReminder(duplicate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lembrete duplicado com sucesso!')),
          );
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir Lembrete'),
            content: Text(
                'Tem certeza que deseja excluir "${reminder.title}"? Todos os alarmes programados serão cancelados.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await ref.read(reminderRepositoryProvider).deleteReminder(reminder.id);
          await ref.read(schedulerServiceProvider).cancelReminder(reminder.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lembrete excluído com sucesso.')),
            );
          }
        }
        break;
    }
  }
}
