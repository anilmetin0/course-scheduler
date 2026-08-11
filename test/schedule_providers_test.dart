import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/features/course_selection/providers/course_providers.dart';

void main() {
  group('Schedule providers', () {
    late ProviderContainer container;

    setUp(() {
      storageService = InMemoryStorageService();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('generates all combinations and filters conflicts', () async {
      // Two course codes, two sections each
      final c1a = Course(
        id: '1',
        code: 'MATH101',
        name: 'Calculus',
        section: 'A',
        schedule: 'Mo 9-11',
      );
      final c1b = Course(
        id: '2',
        code: 'MATH101',
        name: 'Calculus',
        section: 'B',
        schedule: 'Tu 9-11',
      );
      final c2a = Course(
        id: '3',
        code: 'PHYS101',
        name: 'Physics',
        section: 'A',
        schedule: 'Mo 10-12', // overlaps with c1a
      );
      final c2b = Course(
        id: '4',
        code: 'PHYS101',
        name: 'Physics',
        section: 'B',
        schedule: 'We 13-14',
      );

      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourses([c1a, c1b, c2a, c2b]);

      // allow conflicts → 2x2=4
      container.read(allowConflictsProvider.notifier).state = true;
      container.read(minFreeDaysProvider.notifier).state = null;
      var combos = container.read(scheduleCombinationsProvider);
      expect(combos.length, 4);

      // disallow conflicts → remove (c1a,c2a)
      container.read(allowConflictsProvider.notifier).state = false;
      combos = container.read(scheduleCombinationsProvider);
      expect(combos.length, 3);

      // require many free days (4) → no combos (Mon+Wed uses 2 days => 3 free)
      container.read(minFreeDaysProvider.notifier).state = 4;
      combos = container.read(scheduleCombinationsProvider);
      expect(combos, isEmpty);

      // lower to 3 free days → all 3 combos valid
      container.read(minFreeDaysProvider.notifier).state = 3;
      combos = container.read(scheduleCombinationsProvider);
      expect(combos.length, 3);
    });

    test('activeScheduleProvider maps courses into day/hour grid', () async {
      final c1 = Course(
        id: '10',
        code: 'CS101',
        name: 'Intro',
        section: '1',
        schedule: 'Mo 9-11',
      );
      final c2 = Course(
        id: '11',
        code: 'HIST100',
        name: 'History',
        section: '1',
        schedule: 'We 13-15',
      );

      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourses([c1, c2]);
      container.read(allowConflictsProvider.notifier).state = true;
      container.read(minFreeDaysProvider.notifier).state = null;

      final schedule = container.read(activeScheduleProvider);
      // Monday 09:00 and 10:00 should include c1
      expect(schedule['Pazartesi']!['09:00']!.contains(c1), isTrue);
      expect(schedule['Pazartesi']!['10:00']!.contains(c1), isTrue);
      // Wednesday 13:00 and 14:00 should include c2
      expect(schedule['Çarşamba']!['13:00']!.contains(c2), isTrue);
      expect(schedule['Çarşamba']!['14:00']!.contains(c2), isTrue);
    });

    test('handles multi-day groups like "Tu/Fr 13 - 15 Tu/Fr 09 - 12"', () async {
      final c = Course(
        id: '20',
        code: 'ARCH101',
        name: 'Architectural Basics',
        section: '1',
        schedule: 'Tu/Fr 13 - 15 Tu/Fr 09 - 12',
      );

      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourse(c);
      container.read(allowConflictsProvider.notifier).state = true;
      container.read(minFreeDaysProvider.notifier).state = null;

      final schedule = container.read(activeScheduleProvider);

      // Salı 09,10,11
      expect(schedule['Salı']!['09:00']!.contains(c), isTrue);
      expect(schedule['Salı']!['10:00']!.contains(c), isTrue);
      expect(schedule['Salı']!['11:00']!.contains(c), isTrue);
      // Cuma 09,10,11
      expect(schedule['Cuma']!['09:00']!.contains(c), isTrue);
      expect(schedule['Cuma']!['10:00']!.contains(c), isTrue);
      expect(schedule['Cuma']!['11:00']!.contains(c), isTrue);

      // Salı 13,14
      expect(schedule['Salı']!['13:00']!.contains(c), isTrue);
      expect(schedule['Salı']!['14:00']!.contains(c), isTrue);
      // Cuma 13,14
      expect(schedule['Cuma']!['13:00']!.contains(c), isTrue);
      expect(schedule['Cuma']!['14:00']!.contains(c), isTrue);
    });
  });
}
