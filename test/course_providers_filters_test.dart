import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/features/course_selection/providers/course_providers.dart';

void main() {
  group('Course providers filters and grouping', () {
    late ProviderContainer container;
    late List<Course> sampleCourses;

    setUp(() {
      storageService = InMemoryStorageService();
      sampleCourses = const [
        Course(
          id: '1',
          code: 'CS101',
          name: 'Intro',
          section: 'B',
          schedule: 'Mo 9-11',
          lecturer: 'Alice',
          department: 'CS',
        ),
        Course(
          id: '2',
          code: 'CS101',
          name: 'Intro',
          section: 'A',
          schedule: 'Tu 9-11',
          lecturer: 'Bob',
          department: 'CS',
        ),
        Course(
          id: '3',
          code: 'MATH200',
          name: 'Math',
          section: '',
          schedule: 'We 9-11',
          lecturer: 'Carol',
          department: 'MATH',
        ),
      ];

      container = ProviderContainer(
        overrides: [
          coursesProvider.overrideWith((ref) async => sampleCourses),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('filteredCourses uses search query for code/name/lecturer', () async {
      await container.read(coursesProvider.future);

      container.read(searchQueryProvider.notifier).update('bob');
      final results = container.read(filteredCoursesProvider);

      expect(results.length, 1);
      expect(results.single.lecturer, 'Bob');
    });

    test('departmentsProvider returns sorted unique departments', () async {
      await container.read(coursesProvider.future);

      final departments = container.read(departmentsProvider);
      expect(departments, ['CS', 'MATH']);
    });

    test('coursesByDepartment filters when department selected', () async {
      await container.read(coursesProvider.future);

      container.read(selectedDepartmentProvider.notifier).set('CS');
      final results = container.read(coursesByDepartmentProvider);

      expect(results.length, 2);
      expect(results.every((c) => c.department == 'CS'), isTrue);
    });

    test('courseGroupsProvider groups by code and sorts sections', () async {
      await container.read(coursesProvider.future);

      final groups = container.read(courseGroupsProvider);
      expect(groups.length, 2);
      expect(groups.first.code, 'CS101');
      expect(
        groups.first.sections.map((c) => c.section).toList(),
        ['A', 'B'],
      );
    });

    test('CourseColors provider returns deterministic colors and allows overrides', () {
      final notifier = container.read(courseColorsProvider.notifier);
      final first = notifier.getColorForCourse('CS101');
      final second = notifier.getColorForCourse('CS101');
      expect(first, second);

      notifier.setColorForCourse('CS101', Colors.red);
      expect(notifier.getColorForCourse('CS101'), Colors.red);
    });

    test('ActiveCombinationIndex resets when combinations shrink', () {
      final c1 = sampleCourses[0];
      final c2 = sampleCourses[1];
      final c3 = const Course(
        id: '4',
        code: 'MATH200',
        name: 'Math',
        section: '1',
        schedule: 'Th 9-11',
        department: 'MATH',
      );
      final c4 = const Course(
        id: '5',
        code: 'MATH200',
        name: 'Math',
        section: '2',
        schedule: 'Fr 9-11',
        department: 'MATH',
      );

      container.read(allowConflictsProvider.notifier).set(true);
      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourses([c1, c2, c3, c4]);

      container.read(activeCombinationIndexProvider.notifier).setIndex(3);
      expect(container.read(activeCombinationIndexProvider), 3);

      notifier.removeCourses([c3, c4]);
      expect(container.read(activeCombinationIndexProvider), 0);
    });
  });
}
