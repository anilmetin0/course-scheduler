import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/features/schedule/providers/saved_schedules_provider.dart';

void main() {
  group('SavedSchedules provider', () {
    late ProviderContainer container;
    late StorageService previousStorage;

    setUp(() async {
      previousStorage = storageService;
      storageService = InMemoryStorageService();
      container = ProviderContainer(
        overrides: [
          currentDatasetInfoProvider.overrideWith(
            (ref) => const AssetDatasetMeta(
              path: 'assets/sample.json',
              name: 'sample',
              courseCount: 1,
              year: '2024-2025',
              period: '1',
            ),
          ),
          assetDatasetsProvider.overrideWith(
            (ref) async => [
              AssetDatasetMeta(
                path: 'assets/sample.json',
                name: 'sample',
                courseCount: 1,
                year: '2024-2025',
                period: '1',
              ),
            ],
          ),
        ],
      );
      await container.read(savedSchedulesProvider.notifier).load();
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
      storageService = previousStorage;
    });

    Course buildCourse(String id, String code, String schedule) => Course(
      id: id,
      code: code,
      name: code,
      section: '1',
      schedule: schedule,
    );

    test('initial load empty', () async {
      // give microtask for async load
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(container.read(savedSchedulesProvider), isEmpty);
    });

    test('saveSchedule adds new schedule with unique id', () async {
      final c1 = buildCourse('1', 'MATH101', 'Mo 9-11');
      await container
          .read(savedSchedulesProvider.notifier)
          .saveSchedule(
            name: 'Plan 1',
            courses: [c1],
            datasetPath: 'assets/sample.json',
            allowConflicts: false,
            minFreeDays: null,
          );
      final list = container.read(savedSchedulesProvider);
      expect(list.length, 1);
      expect(list.first.name, 'Plan 1');
      expect(list.first.courses.single.code, 'MATH101');
    });

    test('updateSchedule changes name only', () async {
      final c1 = buildCourse('1', 'MATH101', 'Mo 9-11');
      await container
          .read(savedSchedulesProvider.notifier)
          .saveSchedule(
            name: 'Original',
            courses: [c1],
            datasetPath: 'assets/sample.json',
            allowConflicts: false,
            minFreeDays: null,
          );
      final id = container.read(savedSchedulesProvider).first.id;
      await container
          .read(savedSchedulesProvider.notifier)
          .updateSchedule(id, 'Renamed');
      final list = container.read(savedSchedulesProvider);
      expect(list.single.name, 'Renamed');
      expect(list.single.courses.single.code, 'MATH101');
    });

    test('update using alias updates both name and courses', () async {
      final c1 = buildCourse('1', 'MATH101', 'Mo 9-11');
      await container
          .read(savedSchedulesProvider.notifier)
          .saveSchedule(
            name: 'Sched',
            courses: [c1],
            datasetPath: 'assets/sample.json',
            allowConflicts: false,
            minFreeDays: null,
          );
      final id = container.read(savedSchedulesProvider).first.id;
      final c2 = buildCourse('2', 'PHYS101', 'Tu 10-12');
      await container
          .read(savedSchedulesProvider.notifier)
          .update(id, name: 'Updated', courses: [c2]);
      final s = container.read(savedSchedulesProvider).first;
      expect(s.name, 'Updated');
      expect(s.courses.single.code, 'PHYS101');
    });

    test('deleteSchedule removes only target', () async {
      final c1 = buildCourse('1', 'MATH101', 'Mo 9-11');
      final c2 = buildCourse('2', 'PHYS101', 'Tu 10-12');
      await container
          .read(savedSchedulesProvider.notifier)
          .saveSchedule(
            name: 'S1',
            courses: [c1],
            datasetPath: 'assets/sample.json',
            allowConflicts: false,
            minFreeDays: null,
          );
      await container
          .read(savedSchedulesProvider.notifier)
          .saveSchedule(
            name: 'S2',
            courses: [c2],
            datasetPath: 'assets/sample.json',
            allowConflicts: false,
            minFreeDays: null,
          );
      final listBefore = container.read(savedSchedulesProvider);
      expect(listBefore.length, 2);
      final idToRemove = listBefore.first.id;
      await container
          .read(savedSchedulesProvider.notifier)
          .deleteSchedule(idToRemove);
      final listAfter = container.read(savedSchedulesProvider);
      expect(listAfter.length, 1);
      expect(listAfter.single.name, isNot(listBefore.first.name));
    });

    test('activeScheduleCourses persists to storage', () async {
      final c1 = buildCourse('1', 'MATH101', 'Mo 9-11');
      final activeNotifier = container.read(
        activeScheduleCoursesProvider.notifier,
      );
      await activeNotifier.load();
      await activeNotifier.saveActiveCourses([c1]);
      final raw = await storageService.getString('active_schedule_courses');
      expect(raw, isNotNull);
      final decoded = json.decode(raw!) as List<dynamic>;
      expect(decoded.length, 1);
      final restored = decoded
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(restored.length, 1);
      expect(container.read(activeScheduleCoursesProvider).length, 1);

      // Storage format should remain valid for reloads.
    });
  });
}
