import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduler/shared/widgets/analytics_consent_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildHarness(Future<void> Function(BuildContext) onPressed) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async => onPressed(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('showAnalyticsConsentDialog displays dialog when not shown', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness(showAnalyticsConsentDialog));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsConsentDialog), findsOneWidget);
    expect(find.text('Uygulama İyileştirmeleri'), findsOneWidget);
  });

  testWidgets('accepting consent sets prefs and shows snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness(showAnalyticsConsentDialog));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kabul Ediyorum'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('analytics_consent_shown'), isTrue);
    expect(prefs.getBool('analytics_consent'), isTrue);
    expect(
      find.text('Teşekkürler! Bu, uygulamayı geliştirmemize yardımcı olacak.'),
      findsOneWidget,
    );
  });

  testWidgets('dialog not shown again when already shown', (tester) async {
    SharedPreferences.setMockInitialValues({'analytics_consent_shown': true});

    await tester.pumpWidget(buildHarness(showAnalyticsConsentDialog));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsConsentDialog), findsNothing);
  });
}
