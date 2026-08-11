import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/models/saved_schedule.dart';

void main() {
  test('SavedSchedule.fromJson supports legacy keys', () {
    final course = const Course(
      id: '1',
      code: 'CS101',
      name: 'Intro',
      section: 'A',
      schedule: 'Mo 9-11',
    );

    final schedule = SavedSchedule.fromJson({
      'id': 'sched-1',
      'name': 'Plan A',
      'courses': [course.toJson()],
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-02T00:00:00.000Z',
      'allow_conflicts': true,
      'min_free_days': 2,
    });

    expect(schedule.id, 'sched-1');
    expect(schedule.name, 'Plan A');
    expect(schedule.courses.length, 1);
    expect(schedule.allowConflicts, isTrue);
    expect(schedule.minFreeDays, 2);
  });

  test('SavedSchedule.toJson round-trip preserves fields', () {
    final now = DateTime.parse('2024-01-01T12:00:00.000Z');
    final schedule = SavedSchedule(
      id: 'sched-2',
      name: 'Plan B',
      courses: const [
        Course(
          id: '1',
          code: 'MATH200',
          name: 'Math',
          section: '1',
          schedule: 'Tu 9-11',
        ),
      ],
      createdAt: now,
      updatedAt: now,
      allowConflicts: false,
      minFreeDays: 3,
    );

    final json = schedule.toJson();
    final restored = SavedSchedule.fromJson(json);

    expect(restored.id, schedule.id);
    expect(restored.name, schedule.name);
    expect(restored.allowConflicts, schedule.allowConflicts);
    expect(restored.minFreeDays, schedule.minFreeDays);
    expect(restored.courses.single.code, 'MATH200');
  });

  test('SavedSchedule equality uses id and name', () {
    final now = DateTime.parse('2024-01-01T12:00:00.000Z');
    final a = SavedSchedule(
      id: 'id-1',
      name: 'Plan',
      courses: const [],
      createdAt: now,
      updatedAt: now,
    );
    final b = SavedSchedule(
      id: 'id-1',
      name: 'Plan',
      courses: const [],
      createdAt: now,
      updatedAt: now,
    );
    final c = SavedSchedule(
      id: 'id-2',
      name: 'Plan',
      courses: const [],
      createdAt: now,
      updatedAt: now,
    );

    expect(a, b);
    expect(a, isNot(c));
  });
}
