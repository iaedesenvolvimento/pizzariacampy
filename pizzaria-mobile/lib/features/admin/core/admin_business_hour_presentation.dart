import 'package:flutter/material.dart';

abstract final class AdminBusinessHourPresentation {
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String formatRange(TimeOfDay opening, TimeOfDay closing) {
    return '${formatTime(opening)} – ${formatTime(closing)}';
  }

  static bool isValidRange(TimeOfDay opening, TimeOfDay closing) {
    return opening.hour * 60 + opening.minute <
        closing.hour * 60 + closing.minute;
  }

  static TimeOfDay? parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }
}
