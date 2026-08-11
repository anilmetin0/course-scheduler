import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduler/shared/widgets/analytics_consent_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AnalyticsSettingsTile shows disabled state and toggles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnalyticsSettingsTile()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kullanım Analitikleri'), findsOneWidget);
    expect(find.text('Kullanım verileri toplanmıyor'), findsOneWidget);

    final switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    await tester.tap(switchFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(
      find.text('Anonim kullanım ve ders istatistikleri toplanıyor'),
      findsOneWidget,
    );
  });

  testWidgets('AnalyticsSettingsTile reads enabled preference', (tester) async {
    SharedPreferences.setMockInitialValues({'analytics_consent': true});

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnalyticsSettingsTile()),
      ),
    );

    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);
  });
}
