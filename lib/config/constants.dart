import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color surface = Color(0xFFFFFBFE);
  static const Color background = Color(0xFFFFFBFE);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onError = Color(0xFFFFFFFF);
}

class AppConstants {
  static const String appName = 'Ders Programı Oluşturucu';

  // API endpoints
  static const String baseUrl = '';

  // Storage keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
}

/// Shared schedule table configuration (UI lists)
class ScheduleTableConstants {
  // Weekday labels shown in tables (TR)
  static const List<String> days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
  ];

  // Default hourly slots shown in tables
  static const List<String> timeSlots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  // Format time slot for display (e.g., "09:00" -> "09:00-09:50")
  static String formatTimeSlotForDisplay(String timeSlot) {
    if (timeSlot.isEmpty) return timeSlot;

    // Parse hour from "HH:MM" format
    final parts = timeSlot.split(':');
    if (parts.length != 2) return timeSlot;

    final hour = int.tryParse(parts[0]);
    if (hour == null) return timeSlot;

    // Add 50 minutes to show the end time
    return '$timeSlot-${parts[0]}:50';
  }
}
