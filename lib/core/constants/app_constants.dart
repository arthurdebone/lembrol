class AppConstants {
  static const String appName = 'Lembrol';
  static const String appTagline = 'Lembretes Recorrentes Confiáveis';

  // Opções de adiamento (Snooze) permitidas pelo requisito
  static const List<int> snoozeDurationsMinutes = [5, 10, 15];
  static const int defaultSnoozeMinutes = 10;

  // Categorias sugeridas
  static const List<String> defaultCategories = [
    'Saúde e Bem-estar',
    'Postura e Ergonomia',
    'Foco e Produtividade',
    'Visão e Descanso',
    'Medicamentos',
    'Hidratação',
  ];

  // Identificador da aplicação para Windows Toast
  static const String windowsAppUserModelId = 'Lembrol.PersonalReminders.App';
  static const String notificationChannelId = 'lembrol_recurring_channel';
  static const String notificationChannelName = 'Lembretes Recorrentes';
  static const String notificationChannelDescription =
      'Canal de notificações pontuais e recorrentes do Lembrol';
}
