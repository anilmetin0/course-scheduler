import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/features/course_selection/providers/course_providers.dart';

void main() {
  group('SelectedCourses provider', () {
    late ProviderContainer container;

    final courseA1 = Course(
      id: '1',
      code: 'MATH101',
      name: 'Calculus',
      section: 'A',
      schedule: 'Mo 9-11',
    );
    final courseA2 = Course(
      id: '2',
      code: 'MATH101',
      name: 'Calculus',
      section: 'B',
      schedule: 'Tu 9-11',
    );
    final courseB1 = Course(
      id: '3',
      code: 'PHYS101',
      name: 'Physics',
      section: 'A',
      schedule: 'We 13-15',
    );

    setUp(() {
      // In-memory storage to avoid persistence side effects
      storageService = InMemoryStorageService();
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('addCourse adds only once (no duplicates)', () {
      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourse(courseA1);
      notifier.addCourse(courseA1); // duplicate attempt
      expect(container.read(selectedCoursesProvider).length, 1);
    });

    test('removeCourse actually removes', () {
      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourse(courseA1);
      notifier.removeCourse(courseA1);
      expect(container.read(selectedCoursesProvider), isEmpty);
    });

    test('toggleCourse adds then removes', () {
      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.toggleCourse(courseA1);
      expect(container.read(selectedCoursesProvider), contains(courseA1));
      notifier.toggleCourse(courseA1);
      expect(
        container.read(selectedCoursesProvider),
        isNot(contains(courseA1)),
      );
    });

    test('addCourses merges unique courses', () {
      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourse(courseA1);
      notifier.addCourses([courseA1, courseA2, courseB1]); // includes duplicate
      final list = container.read(selectedCoursesProvider);
      expect(list.length, 3);
      expect(list, containsAll([courseA1, courseA2, courseB1]));
    });

    test('removeCourses removes only specified subset', () {
      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourses([courseA1, courseA2, courseB1]);
      notifier.removeCourses([courseA1, courseB1]);
      final list = container.read(selectedCoursesProvider);
      expect(list.length, 1);
      expect(list.single, courseA2);
    });

    test('select/deselect all sections helpers', () {
      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.selectAllSections([courseA1, courseA2]);
      expect(container.read(selectedCoursesProvider).length, 2);
      notifier.deselectAllSections([courseA1]);
      expect(container.read(selectedCoursesProvider).length, 1);
      notifier.toggleAllSections([
        courseA1,
        courseA2,
      ]); // adds removed + adds missing
      expect(container.read(selectedCoursesProvider).length, 2);
      notifier.toggleAllSections([courseA1, courseA2]); // now removes both
      expect(container.read(selectedCoursesProvider).length, 0);
    });

    test('areAllSelected reflects state', () {
      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourses([courseA1, courseA2]);
      expect(
        container.read(selectedCoursesProvider.notifier).areAllSelected([
          courseA1,
          courseA2,
        ]),
        isTrue,
      );
      expect(
        container.read(selectedCoursesProvider.notifier).areAllSelected([
          courseA1,
          courseB1,
        ]),
        isFalse,
      );
    });

    test('clearAll empties selection', () {
      final notifier = container.read(selectedCoursesProvider.notifier);
      notifier.addCourses([courseA1, courseA2, courseB1]);
      notifier.clearAll();
      expect(container.read(selectedCoursesProvider), isEmpty);
    });
  });
}
