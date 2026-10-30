import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeFormatters {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  static String formatCountdown(Duration duration) {
    if (duration.isNegative) {
      return 'Agora';
    }
    final inSeconds = duration.inSeconds;
    if (inSeconds < 60) {
      return '${inSeconds}s';
    }
    final inMinutes = duration.inMinutes;
    if (inMinutes < 60) {
      return '$inMinutes min';
    }
    final hours = duration.inHours;
    final remainingMinutes = inMinutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  static String formatRelativeDateTime(DateTime target, DateTime now) {
    final localTarget = target.toLocal();
    final localNow = now.toLocal();

    final isToday = localTarget.year == localNow.year &&
        localTarget.month == localNow.month &&
        localTarget.day == localNow.day;

    final tomorrow = localNow.add(const Duration(days: 1));
    final isTomorrow = localTarget.year == tomorrow.year &&
        localTarget.month == tomorrow.month &&
        localTarget.day == tomorrow.day;

    final timeStr = formatTime(localTarget);

    if (isToday) {
      return 'Hoje às $timeStr';
    } else if (isTomorrow) {
      return 'Amanhã às $timeStr';
    } else {
      final weekday = getWeekdayShortName(localTarget.weekday);
      return '$weekday, ${formatDate(localTarget)} às $timeStr';
    }
  }

  static String getWeekdayShortName(int isoWeekday) {
    switch (isoWeekday) {
      case DateTime.monday:
        return 'Seg';
      case DateTime.tuesday:
        return 'Ter';
      case DateTime.wednesday:
        return 'Qua';
      case DateTime.thursday:
        return 'Qui';
      case DateTime.friday:
        return 'Sex';
      case DateTime.saturday:
        return 'Sáb';
      case DateTime.sunday:
        return 'Dom';
      default:
        return '';
    }
  }

  static String getWeekdayFullName(int isoWeekday) {
    switch (isoWeekday) {
      case DateTime.monday:
        return 'Segunda-feira';
      case DateTime.tuesday:
        return 'Terça-feira';
      case DateTime.wednesday:
        return 'Quarta-feira';
      case DateTime.thursday:
        return 'Quinta-feira';
      case DateTime.friday:
        return 'Sexta-feira';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return '';
    }
  }

  static String formatSelectedDays(Set<int> days) {
    if (days.isEmpty) return 'Nenhum dia';
    if (days.length == 7) return 'Todos os dias';
    final weekdaysOnly = {1, 2, 3, 4, 5};
    final weekendOnly = {6, 7};
    if (days.length == 5 && days.containsAll(weekdaysOnly)) {
      return 'Dias úteis (Seg - Sex)';
    }
    if (days.length == 2 && days.containsAll(weekendOnly)) {
      return 'Fim de semana (Sáb - Dom)';
    }

    final sorted = days.toList()..sort();
    return sorted.map(getWeekdayShortName).join(', ');
  }
}
