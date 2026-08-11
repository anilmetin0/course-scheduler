import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/features/datasets/pages/course_comparison_page.dart';

void main() {
  testWidgets('CourseComparisonPage shows empty state when no datasets', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CourseComparisonPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ders Karşılaştırması'), findsOneWidget);
    expect(find.text('Veri Setleri Sayfasına Dön'), findsOneWidget);
  });
}
