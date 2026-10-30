import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_templates.dart';
import '../../../core/utils/time_formatters.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/recurrence/recurrence_engine.dart';
import '../../../domain/recurrence/recurrence_validator.dart';
import '../../providers/app_providers.dart';
import '../../widgets/day_selector.dart';

class ReminderFormScreen extends ConsumerStatefulWidget {
  final String? reminderId;
  final ReminderTemplate? initialTemplate;

  const ReminderFormScreen({
    super.key,
    this.reminderId,
    this.initialTemplate,
  });

  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _intervalController;
  String? _selectedCategory;

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  Set<int> _selectedDays = {1, 2, 3, 4, 5}; // Seg a Sex por padrão
  bool _isActive = true;
  bool _enableVisual = true;
  bool _enableSound = true;
  bool _enableVibration = true;

  bool _isLoading = true;
  Reminder? _existingReminder;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _intervalController = TextEditingController(text: '60');

    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.reminderId != null) {
      final reminder = await ref
          .read(reminderRepositoryProvider)
          .getReminderById(widget.reminderId!);
      if (reminder != null) {
        _existingReminder = reminder;
        _titleController.text = reminder.title;
        _descriptionController.text = reminder.description ?? '';
        _intervalController.text = reminder.intervalMinutes.toString();
        _selectedCategory = reminder.category;
        _startTime = reminder.startTime;
        _endTime = reminder.endTime;
        _selectedDays = Set.from(reminder.selectedDays);
        _isActive = reminder.isActive;
        _enableVisual = reminder.enableVisual;
        _enableSound = reminder.enableSound;
        _enableVibration = reminder.enableVibration;
      }
    } else if (widget.initialTemplate != null) {
      final t = widget.initialTemplate!;
      _titleController.text = t.title;
      _descriptionController.text = t.description;
      _intervalController.text = t.intervalMinutes.toString();
      _selectedCategory = t.category;
      _startTime = TimeOfDay(hour: t.defaultStartHour, minute: t.defaultStartMinute);
      _endTime = TimeOfDay(hour: t.defaultEndHour, minute: t.defaultEndMinute);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _setIntervalShortcut(int minutes) {
    setState(() {
      _intervalController.text = minutes.toString();
    });
  }

  List<DateTime> _calculateLivePreview() {
    final interval = int.tryParse(_intervalController.text) ?? 60;
    final tempReminder = Reminder(
      id: 'preview',
      title: _titleController.text.isNotEmpty ? _titleController.text : 'Prévia',
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      intervalMinutes: interval,
      selectedDays: _selectedDays,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final clock = ref.read(clockProvider);
    return RecurrenceEngine.getUpcomingOccurrences(
      reminder: tempReminder,
      fromDateTime: clock.now(),
      limit: 5,
    );
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final interval = int.parse(_intervalController.text.trim());

    final validation = RecurrenceValidator.validateAll(
      title: _titleController.text.trim(),
      intervalMinutes: interval,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      selectedDays: _selectedDays,
    );

    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final reminderToSave = Reminder(
      id: _existingReminder?.id ?? _uuid.v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      intervalMinutes: interval,
      selectedDays: _selectedDays,
      isActive: _isActive,
      category: _selectedCategory,
      enableVisual: _enableVisual,
      enableSound: _enableSound,
      enableVibration: _enableVibration,
      snoozeUntil: _existingReminder?.snoozeUntil,
      createdAt: _existingReminder?.createdAt ?? now,
      updatedAt: now,
    );

    // Salva na persistência
    await ref.read(reminderRepositoryProvider).saveReminder(reminderToSave);

    // Atualiza agendador independente
    await ref
        .read(schedulerServiceProvider)
        .scheduleNextForReminder(reminderToSave);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.reminderId != null
                ? 'Lembrete atualizado com sucesso!'
                : 'Lembrete criado com sucesso!',
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final previewOccurrences = _calculateLivePreview();
    final isEditing = widget.reminderId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Lembrete' : 'Novo Lembrete'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: const Text('Salvar'),
            onPressed: _saveReminder,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Campo de Título
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título do lembrete *',
                hintText: 'Ex: Beber água, Descansar os olhos...',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final res = RecurrenceValidator.validateTitle(v);
                return res.isValid ? null : res.errorMessage;
              },
            ),
            const SizedBox(height: 12),

            // Campo de Descrição (opcional)
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Instruções ou Descrição (opcional)',
                hintText: 'Ex: Beber 300ml de água mineral fresca',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Categoria
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria (opcional)',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Nenhuma categoria'),
                ),
                ...AppConstants.defaultCategories.map(
                  (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                ),
              ],
              onChanged: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 20),

            // Janela de Horários (Início e Fim)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Janela de Horários',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Os disparos começam no horário inicial e cessam no horário final.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickStartTime,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Início',
                                prefixIcon: Icon(Icons.wb_sunny_outlined),
                              ),
                              child: Text(
                                TimeFormatters.formatTimeOfDay(_startTime),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndTime,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fim (inclusivo)',
                                prefixIcon: Icon(Icons.bedtime_outlined),
                              ),
                              child: Text(
                                TimeFormatters.formatTimeOfDay(_endTime),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_endTime.hour * 60 + _endTime.minute <=
                        _startTime.hour * 60 + _startTime.minute) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Atenção: O horário final deve ser posterior ao inicial.',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Intervalo de Repetição
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intervalo de Repetição',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _intervalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Repetir a cada (minutos) *',
                        prefixIcon: Icon(Icons.timer_outlined),
                        suffixText: 'minutos',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final parsed = int.tryParse(v ?? '');
                        final res = RecurrenceValidator.validateInterval(parsed);
                        return res.isValid ? null : res.errorMessage;
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          label: const Text('15 min'),
                          onPressed: () => _setIntervalShortcut(15),
                        ),
                        ActionChip(
                          label: const Text('30 min'),
                          onPressed: () => _setIntervalShortcut(30),
                        ),
                        ActionChip(
                          label: const Text('40 min'),
                          onPressed: () => _setIntervalShortcut(40),
                        ),
                        ActionChip(
                          label: const Text('1 hora'),
                          onPressed: () => _setIntervalShortcut(60),
                        ),
                        ActionChip(
                          label: const Text('2 horas'),
                          onPressed: () => _setIntervalShortcut(120),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Seleção de Dias da Semana
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DaySelector(
                  selectedDays: _selectedDays,
                  onChanged: (days) => setState(() => _selectedDays = days),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prévia dos Próximos Horários (Requisito 4.2)
            Card(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Prévia dos Próximos Disparos',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (previewOccurrences.isEmpty)
                      const Text(
                        'Ajuste os horários e dias para visualizar a programação.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      ...previewOccurrences.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final dt = entry.value;
                        final clock = ref.read(clockProvider);
                        final label =
                            TimeFormatters.formatRelativeDateTime(dt, clock.now());

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$index',
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
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notificações e Sons
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opções de Notificação',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notificação Visual'),
                      subtitle: const Text('Exibe banner ou toast no sistema'),
                      value: _enableVisual,
                      onChanged: (v) => setState(() => _enableVisual = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Som'),
                      subtitle: const Text('Toca aviso sonoro do sistema'),
                      value: _enableSound,
                      onChanged: (v) => setState(() => _enableSound = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vibração'),
                      subtitle: const Text('Vibra em dispositivos móveis compatíveis'),
                      value: _enableVibration,
                      onChanged: (v) => setState(() => _enableVibration = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lembrete Ativo'),
                      subtitle: const Text('Lembretes inativos não emitem avisos'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botão Salvar
            ElevatedButton(
              onPressed: _saveReminder,
              child: Text(
                isEditing ? 'Atualizar Lembrete' : 'Salvar Lembrete',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
