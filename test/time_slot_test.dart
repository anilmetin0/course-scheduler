import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/core/models/time_slot.dart';

void main() {
  group('TimeSlot.fromSchedule', () {
    test('parses English short form with spaces around dash', () {
      final ts = TimeSlot.fromSchedule('We 16 - 19');
      expect(ts.day, 'Çarşamba');
      expect(ts.startHour, 16);
      expect(ts.endHour, 19);
    });

    test('parses English short form without spaces around dash', () {
      final ts = TimeSlot.fromSchedule('Mo 9-11');
      expect(ts.day, 'Pazartesi');
      expect(ts.startHour, 9);
      expect(ts.endHour, 11);
    });

    test('parses Turkish and English full names', () {
      final t1 = TimeSlot.fromSchedule('Pazartesi 9-10');
      final t2 = TimeSlot.fromSchedule('Monday 10-12');
      expect(t1.day, 'Pazartesi');
      expect(t2.day, 'Pazartesi');
    });

    test('returns empty for invalid schedule', () {
      final ts = TimeSlot.fromSchedule('Invalid');
      expect(ts.day, '');
      expect(ts.startHour, 0);
      expect(ts.endHour, 0);
    });
  });

  group('TimeSlot JSON', () {
    test('toJson/fromJson round-trip', () {
      const original = TimeSlot(day: 'Salı', startHour: 9, endHour: 11);
      final json = original.toJson();
      final restored = TimeSlot.fromJson(json);
      expect(restored, original);
    });
  });
}
