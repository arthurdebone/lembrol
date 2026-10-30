import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_templates.dart';
import '../../../core/utils/time_formatters.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/recurrence/recurrence_engine.dart';
import '../../../platform/scheduler/reminder_scheduler_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/permission_banner.dart';
import '../../widgets/template_picker_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Atualiza o relógio da contagem regressiva a cada segundo
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _openTemplatePicker() async {
    final template = await showDialog<ReminderTemplate>(
      context: context,
      builder: (ctx) => const TemplatePickerDialog(),
    );

    if (template != null && mounted) {
      context.push('/reminders/create', extra: template);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remindersAsync = ref.watch(remindersStreamProvider);
    final diagnosticsAsync = ref.watch(diagnosticsProvider);
    final clock = ref.watch(clockProvider);
    final scheduler = ref.watch(schedulerServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.alarm_on_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Lembrol'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Modelos rápidos',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: _openTemplatePicker,
          ),
          IconButton(
            tooltip: 'Novo lembrete',
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: () => context.push('/reminders/create'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await scheduler.rescheduleAll();
          ref.invalidate(diagnosticsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Banner de permissões, se necessário
            diagnosticsAsync.when(
              data: (diag) => PermissionBanner(
                diagnostics: diag,
                onRequestPermissions: () async {
                  await ref.read(permissionManagerProvider).requestAllPermissions();
                  ref.invalidate(diagnosticsProvider);
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            remindersAsync.when(
              data: (reminders) {
                if (reminders.isEmpty) {
                  return _buildEmptyState(theme);
                }

                final activeReminders =
                    reminders.where((r) => r.isActive).toList();
                final pausedReminders =
                    reminders.where((r) => !r.isActive).toList();

                // Identifica o próximo disparo mais urgente
                final nextUpcoming =
                    scheduler.getNextUpcomingItem(activeReminders);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Hero do Próximo Disparo
                    if (nextUpcoming != null)
                      _buildNextUpcomingHero(nextUpcoming, clock.now(), theme)
                    else
                      _buildNoActiveScheduleBanner(theme),

                    const SizedBox(height: 24),

                    // Seção de Lembretes Ativos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lembretes Ativos (${activeReminders.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.list_alt_rounded, size: 18),
                          label: const Text('Ver todos'),
                          onPressed: () => context.go('/reminders'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (activeReminders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhum lembrete ativo no momento.',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                      )
                    else
                      ...activeReminders.map(
                        (r) => _buildReminderItemCard(r, clock.now(), theme),
                      ),

                    // Seção de Lembretes Pausados
                    if (pausedReminders.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Pausados (${pausedReminders.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pausedReminders.map(
                        (r) => _buildReminderItemCard(r, clock.now(), theme),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erro ao carregar lembretes: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reminders/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Lembrete'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Seu dia sem esquecimentos',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure lembretes recorrentes para beber água, descansar os olhos, levantar ou tomar remédios.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Criar Lembrete'),
                onPressed: () => context.push('/reminders/create'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Usar um Modelo'),
                onPressed: _openTemplatePicker,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextUpcomingHero(
    ScheduledReminderItem item,
    DateTime now,
    ThemeData theme,
  ) {
    final diff = item.nextOccurrence.difference(now);
    final countdownStr = TimeFormatters.formatCountdown(diff);
    final targetStr =
        TimeFormatters.formatRelativeDateTime(item.nextOccurrence, now);

    final isSnoozed = item.reminder.isSnoozedAt(now);

    return Card(
      color: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timer_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PRÓXIMO LEMBRETE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSnoozed ? 'ADIADO' : 'EM $countdownStr',
                    style: const TextStyle(
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
              item.reminder.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.reminder.description != null &&
                item.reminder.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.reminder.description!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_filled,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  targetStr,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  'A cada ${item.reminder.intervalMinutes} min',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _showSnoozeOptions(item.reminder.id),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.snooze_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Adiar...'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  onPressed: () async {
                    await ref
                        .read(schedulerServiceProvider)
                        .completeOccurrence(item.reminder.id);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Concluir'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveScheduleBanner(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.bedtime_rounded, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Nenhum alarme restante programado para hoje. Os disparos recomeçam no próximo dia ativo.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItemCard(
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
        : 'Sem agendamentos futuros';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: reminder.isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            reminder.isActive ? Icons.alarm_rounded : Icons.alarm_off_rounded,
            color: reminder.isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                reminder.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration:
                      reminder.isActive ? null : TextDecoration.lineThrough,
                  color: reminder.isActive ? null : theme.colorScheme.outline,
                ),
              ),
            ),
            if (reminder.category != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  reminder.category!,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Próximo: $nextTimeStr',
              style: TextStyle(
                fontSize: 12,
                color: reminder.isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                fontWeight:
                    reminder.isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Das ${TimeFormatters.formatTimeOfDay(reminder.startTime)} às ${TimeFormatters.formatTimeOfDay(reminder.endTime)} • A cada ${reminder.intervalMinutes}m',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onPressed: () => context.push('/reminders/${reminder.id}'),
            ),
          ],
        ),
        onTap: () => context.push('/reminders/${reminder.id}'),
      ),
    );
  }

  void _showSnoozeOptions(String reminderId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adiar disparo atual',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A sequência regular dos próximos disparos não será alterada.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
}
