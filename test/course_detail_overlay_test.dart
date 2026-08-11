import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/shared/widgets/course_detail_overlay.dart';

void main() {
  testWidgets('CourseDetailOverlay shows course details and closes', (
    tester,
  ) async {
    const course = Course(
      id: '1',
      code: 'CS101',
      name: 'Intro to CS',
      section: 'A',
      schedule: 'Mo 9-11',
      lecturer: 'Dr Ada',
      room: 'B-101',
      credits: 3,
      department: 'CS',
    );

    final container = ProviderContainer(
      overrides: [
        assetDatasetsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CourseDetailOverlay.show(
                    context,
                    course: course,
                    accentColor: Colors.blue,
                    heroTag: 'course-hero',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('CS101'), findsOneWidget);
    expect(find.text('Intro to CS'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);
    expect(find.text('Dr Ada'), findsOneWidget);
    expect(find.text('Mo 9-11'), findsOneWidget);
    expect(find.text('B-101'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('CS101'), findsNothing);
  });
}
