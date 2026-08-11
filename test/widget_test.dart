// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/main.dart';
import 'package:scheduler/core/services/storage_service.dart';

void main() {
  testWidgets('Scheduler app smoke test', (WidgetTester tester) async {
    // Override storage with in-memory to avoid Hive init in tests
    storageService = InMemoryStorageService();

    await tester.pumpWidget(const ProviderScope(child: SchedulerApp()));
    await tester.pumpAndSettle();

    // App home is SchedulePage with title 'Ders Programı'
    expect(find.text('Ders Programı'), findsOneWidget);
  });
}
