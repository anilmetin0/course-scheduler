import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/shared/widgets/course_history_section.dart';

void main() {
  testWidgets('CourseHistorySection renders history rows from datasets', (
    tester,
  ) async {
    final metas = [
      AssetDatasetMeta(
        path: 'assets/schedules/2023-2024_001.json',
        name: '2023-2024_001',
        courseCount: 1,
        year: '2023-2024',
        period: '1',
        updatedAt: DateTime(2024, 1, 1, 12, 0),
      ),
      AssetDatasetMeta(
        path: 'assets/schedules/2022-2023_001.json',
        name: '2022-2023_001',
        courseCount: 1,
        year: '2022-2023',
        period: '1',
      ),
    ];

    final dataByPath = <String, List<Map<String, dynamic>>>{
      'assets/schedules/2023-2024_001.json': [
        {
          'Code': 'CS101',
          'Section': 'CS101_01',
          '# of Students': '30',
          'Successfull': '20',
          'Conditional': '5',
          'Unsuccessfull': '5',
          'Average': '2.50',
          'Lecturer': 'Dr Test',
        },
        {
          'Code': 'MATH200',
          'Section': 'MATH200_01',
          '# of Students': '40',
        },
      ],
    };

    final container = ProviderContainer(
      overrides: [
        assetDatasetsProvider.overrideWith((ref) async => metas),
        assetDatasetCoursesProvider.overrideWith(
          (ref, path) async => dataByPath[path] ?? const [],
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(selectedAssetCompareProvider.notifier)
        .setAll({'assets/schedules/2023-2024_001.json'});

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: CourseHistorySection(code: 'CS101')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Geçmiş Dönem Bilgileri'), findsOneWidget);
    expect(find.text('2023-2024 1. dönem'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
    expect(find.text('2.50'), findsOneWidget);
    expect(find.text('Dr Test'), findsOneWidget);
  });
}
