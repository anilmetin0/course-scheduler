class TimeSlot {
  final String day;
  final int startHour;
  final int endHour;

  const TimeSlot({
    required this.day,
    required this.startHour,
    required this.endHour,
  });

  factory TimeSlot.fromSchedule(String schedule) {
    if (schedule.isEmpty) {
      return const TimeSlot(day: '', startHour: 0, endHour: 0);
    }

    try {
      // Format: "We 16 - 19" veya "Pazartesi 9-10" veya "Monday 9-10"
      final parts = schedule.trim().split(' ');
      if (parts.length < 2) {
        return const TimeSlot(day: '', startHour: 0, endHour: 0);
      }

      final day = _normalizeDayName(parts[0]);

      // Handle "16 - 19" format (with spaces around dash)
      String timePart;
      if (parts.length >= 4 && parts[2] == '-') {
        timePart = '${parts[1]}-${parts[3]}';
      } else {
        timePart = parts[1];
      }

      if (timePart.contains('-')) {
        final timeParts = timePart.split('-');
        if (timeParts.length == 2) {
          final startHour = int.tryParse(timeParts[0].trim()) ?? 0;
          final endHour = int.tryParse(timeParts[1].trim()) ?? 0;
          return TimeSlot(day: day, startHour: startHour, endHour: endHour);
        }
      }
    } catch (e) {
      // Hata durumunda boş TimeSlot döndür
    }

    return const TimeSlot(day: '', startHour: 0, endHour: 0);
  }

  static String _normalizeDayName(String day) {
    final dayMap = {
      // Turkish full names
      'pazartesi': 'Pazartesi',
      'salı': 'Salı',
      'çarşamba': 'Çarşamba',
      'perşembe': 'Perşembe',
      'cuma': 'Cuma',
      'cumartesi': 'Cumartesi',
      'pazar': 'Pazar',
      // English full names
      'monday': 'Pazartesi',
      'tuesday': 'Salı',
      'wednesday': 'Çarşamba',
      'thursday': 'Perşembe',
      'friday': 'Cuma',
      'saturday': 'Cumartesi',
      'sunday': 'Pazar',
      // English abbreviations
      'mo': 'Pazartesi',
      'tu': 'Salı',
      'we': 'Çarşamba',
      'th': 'Perşembe',
      'fr': 'Cuma',
      'sa': 'Cumartesi',
      'su': 'Pazar',
      // Common alternative abbreviations
      'mon': 'Pazartesi',
      'tue': 'Salı',
      'wed': 'Çarşamba',
      'thu': 'Perşembe',
      'fri': 'Cuma',
      'sat': 'Cumartesi',
      'sun': 'Pazar',
    };

    return dayMap[day.toLowerCase()] ?? day;
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'startHour': startHour, 'endHour': endHour};
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      day: json['day']?.toString() ?? '',
      startHour: json['startHour']?.toInt() ?? 0,
      endHour: json['endHour']?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot &&
        other.day == day &&
        other.startHour == startHour &&
        other.endHour == endHour;
  }

  @override
  int get hashCode {
    return day.hashCode ^ startHour.hashCode ^ endHour.hashCode;
  }

  @override
  String toString() {
    return 'TimeSlot(day: $day, startHour: $startHour, endHour: $endHour)';
  }
}
