import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/models/time_slot.dart';
import 'package:scheduler/core/services/course_service.dart';

void main() {
  setUp(() {
    CourseService().clearCache();
  });

  test('CourseService loads from JSON string and filters schedules', () async {
    const sample = {
      'courses': [
        {
          'Code': 'MATH101',
          'Name': 'Calculus I',
          'Lecturer': 'Prof. A',
          'Section': '1',
          'Schedule': 'Mo 9-11',
          '# of Students': '30'
        },
        {
          'Code': 'STAT201',
          'Name': 'Statistics',
          'Lecturer': 'Prof. B',
          'Section': 'A',
          'Schedule': '',
          '# of Students': '40'
        }
      ]
    };

    final service = CourseService();
    final list = await service.loadCoursesFromString(jsonEncode(sample));

    // One course should be filtered out (no schedule)
    expect(list.length, 1);
    final Course c = list.first;
    expect(c.code, 'MATH101');
    expect(c.timeSlot.day.isNotEmpty, true);
  });

  test('CourseService search matches code, name, and lecturer', () async {
    const sample = {
      'courses': [
        {
          'Code': 'MATH101',
          'Name': 'Calculus I',
          'Lecturer': 'Prof A',
          'Section': '1',
          'Schedule': 'Mo 9-11',
        },
        {
          'Code': 'PHYS201',
          'Name': 'Physics',
          'Lecturer': 'Prof B',
          'Section': '1',
          'Schedule': 'Tu 9-11',
        },
      ],
    };

    final service = CourseService();
    await service.loadCoursesFromString(jsonEncode(sample));

    expect(service.searchCourses('math').length, 1);
    expect(service.searchCourses('Physics').length, 1);
    expect(service.searchCourses('Prof B').length, 1);
  });

  test('CourseService getCoursesForDay and getCoursesByTime', () async {
    const sample = {
      'courses': [
        {
          'Code': 'CS101',
          'Name': 'Intro',
          'Section': '1',
          'Schedule': 'Mo 9-11',
        },
        {
          'Code': 'HIST100',
          'Name': 'History',
          'Section': '1',
          'Schedule': 'We 13-15',
        },
      ],
    };

    final service = CourseService();
    await service.loadCoursesFromString(jsonEncode(sample));

    final day = TimeSlot.fromSchedule('Mo 9-11').day;
    expect(service.getCoursesForDay(day).length, 1);
    expect(service.getCoursesByTime(day, 9).length, 1);
    expect(service.getCoursesByTime(day, 11).length, 0);
  });

  test('CourseService caches by cacheKey', () async {
    const sampleA = {
      'courses': [
        {
          'Code': 'CS101',
          'Name': 'Intro',
          'Section': '1',
          'Schedule': 'Mo 9-11',
        },
      ],
    };
    const sampleB = {
      'courses': [
        {
          'Code': 'MATH200',
          'Name': 'Math',
          'Section': '1',
          'Schedule': 'Tu 9-11',
        },
      ],
    };

    final service = CourseService();
    final first = await service.loadCoursesFromString(
      jsonEncode(sampleA),
      cacheKey: 'k1',
    );
    final cached = await service.loadCoursesFromString(
      jsonEncode(sampleB),
      cacheKey: 'k1',
    );
    final refreshed = await service.loadCoursesFromString(
      jsonEncode(sampleB),
      cacheKey: 'k2',
    );

    expect(first.single.code, 'CS101');
    expect(cached.single.code, 'CS101');
    expect(refreshed.single.code, 'MATH200');
  });
}
