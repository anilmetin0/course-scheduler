import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/models/time_slot.dart';

void main() {
  test('Course.fromJson reads legacy keys and parses schedule', () {
    final course = Course.fromJson({
      'Code': 'MATH101',
      'Name': 'Calculus',
      'Section': '1',
      'Schedule': 'Mo 9-11',
      'Cr': '3',
      'Lecturer': 'Prof A',
      '# of Students': '30',
      'Dept.': 'MATH',
    });

    expect(course.code, 'MATH101');
    expect(course.name, 'Calculus');
    expect(course.section, '1');
    expect(course.credits, 3);
    expect(course.lecturer, 'Prof A');
    expect(course.capacity, 30);
    expect(course.timeSlot.startHour, 9);
    expect(course.timeSlot.endHour, 11);
    expect(course.timeSlot.day, isNotEmpty);
  });

  test('Course.fromJson prefers explicit timeSlot when provided', () {
    final course = Course.fromJson({
      'code': 'CS101',
      'name': 'Intro',
      'schedule': 'Mo 9-11',
      'timeSlot': {'day': 'Tue', 'startHour': 10, 'endHour': 12},
    });

    expect(
      course.timeSlot,
      const TimeSlot(day: 'Tue', startHour: 10, endHour: 12),
    );
  });

  test('Course.copyWith updates selected fields only', () {
    final base = Course(
      id: '1',
      code: 'CS101',
      name: 'Intro',
      section: 'A',
      schedule: 'Mo 9-11',
    );

    final updated = base.copyWith(name: 'Intro 2', credits: 4);

    expect(updated.name, 'Intro 2');
    expect(updated.credits, 4);
    expect(updated.code, base.code);
    expect(updated.section, base.section);
  });

  test('Course equality uses id, code, name, section', () {
    const a = Course(
      id: '1',
      code: 'CS101',
      name: 'Intro',
      section: 'A',
    );
    const b = Course(
      id: '1',
      code: 'CS101',
      name: 'Intro',
      section: 'A',
    );
    const c = Course(
      id: '2',
      code: 'CS101',
      name: 'Intro',
      section: 'A',
    );

    expect(a, b);
    expect(a, isNot(c));
  });

  test('Course toJson round-trip preserves core fields', () {
    const base = Course(
      id: '1',
      code: 'CS101',
      name: 'Intro',
      section: 'A',
      schedule: 'Mo 9-11',
      credits: 3,
    );

    final json = base.toJson();
    final restored = Course.fromJson(json);

    expect(restored.id, base.id);
    expect(restored.code, base.code);
    expect(restored.name, base.name);
    expect(restored.section, base.section);
    expect(restored.credits, base.credits);
  });
}
