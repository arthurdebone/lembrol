class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.invalid(this.errorMessage) : isValid = false;
}

class RecurrenceValidator {
  static const int minTitleLength = 1;
  static const int maxTitleLength = 80;

  static ValidationResult validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return const ValidationResult.invalid('O título do lembrete é obrigatório.');
    }
    if (title.trim().length > maxTitleLength) {
      return const ValidationResult.invalid(
          'O título deve ter no máximo $maxTitleLength caracteres.');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateInterval(int? intervalMinutes) {
    if (intervalMinutes == null || intervalMinutes <= 0) {
      return const ValidationResult.invalid(
          'O intervalo deve ser um número inteiro positivo em minutos.');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateTimeWindow({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) {
    if (startHour < 0 || startHour > 23 || startMinute < 0 || startMinute > 59) {
      return const ValidationResult.invalid('Horário inicial inválido.');
    }
    if (endHour < 0 || endHour > 23 || endMinute < 0 || endMinute > 59) {
      return const ValidationResult.invalid('Horário final inválido.');
    }

    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;

    if (endTotalMinutes <= startTotalMinutes) {
      return const ValidationResult.invalid(
          'O horário final deve ser estritamente posterior ao horário inicial. Janelas que cruzam a meia-noite não são suportadas na versão atual.');
    }

    return const ValidationResult.valid();
  }

  static ValidationResult validateSelectedDays(Set<int>? selectedDays) {
    if (selectedDays == null || selectedDays.isEmpty) {
      return const ValidationResult.invalid(
          'Selecione pelo menos um dia da semana para o lembrete.');
    }
    for (final day in selectedDays) {
      if (day < 1 || day > 7) {
        return const ValidationResult.invalid(
            'Dia da semana inválido (deve ser entre 1 para segunda e 7 para domingo).');
      }
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateAll({
    required String? title,
    required int? intervalMinutes,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required Set<int>? selectedDays,
  }) {
    final titleResult = validateTitle(title);
    if (!titleResult.isValid) return titleResult;

    final intervalResult = validateInterval(intervalMinutes);
    if (!intervalResult.isValid) return intervalResult;

    final windowResult = validateTimeWindow(
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
    );
    if (!windowResult.isValid) return windowResult;

    final daysResult = validateSelectedDays(selectedDays);
    if (!daysResult.isValid) return daysResult;

    return const ValidationResult.valid();
  }
}
