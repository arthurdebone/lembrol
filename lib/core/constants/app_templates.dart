class ReminderTemplate {
  final String title;
  final String description;
  final int intervalMinutes;
  final String category;
  final int defaultStartHour;
  final int defaultStartMinute;
  final int defaultEndHour;
  final int defaultEndMinute;

  const ReminderTemplate({
    required this.title,
    required this.description,
    required this.intervalMinutes,
    required this.category,
    this.defaultStartHour = 8,
    this.defaultStartMinute = 0,
    this.defaultEndHour = 18,
    this.defaultEndMinute = 0,
  });
}

class AppTemplates {
  static const List<ReminderTemplate> initialTemplates = [
    ReminderTemplate(
      title: 'Beber água',
      description: 'Hora de se hidratar! Tome um copo d\'água para manter a saúde.',
      intervalMinutes: 60,
      category: 'Hidratação',
      defaultStartHour: 8,
      defaultStartMinute: 0,
      defaultEndHour: 18,
      defaultEndMinute: 0,
    ),
    ReminderTemplate(
      title: 'Descansar os olhos',
      description: 'Regra 20-20-20: olhe para um ponto distante a 6 metros por 20 segundos.',
      intervalMinutes: 40,
      category: 'Visão e Descanso',
      defaultStartHour: 9,
      defaultStartMinute: 0,
      defaultEndHour: 18,
      defaultEndMinute: 0,
    ),
    ReminderTemplate(
      title: 'Levantar e alongar',
      description: 'Levante da cadeira, estique as pernas, gire os ombros e respire fundo.',
      intervalMinutes: 120,
      category: 'Postura e Ergonomia',
      defaultStartHour: 8,
      defaultStartMinute: 30,
      defaultEndHour: 18,
      defaultEndMinute: 0,
    ),
  ];
}
