import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/shared/widgets/app_snackbar.dart';

void main() {
  Widget buildHarness(void Function(BuildContext) onPressed) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('Show'),
          ),
        ),
      ),
    );
  }

  testWidgets('AppSnackBar.show displays message', (tester) async {
    await tester.pumpWidget(buildHarness(
      (context) => AppSnackBar.show(context, 'Hello'),
    ));

    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('AppSnackBar.showSuccess uses green styling', (tester) async {
    await tester.pumpWidget(buildHarness(
      (context) => AppSnackBar.showSuccess(context, 'Success'),
    ));

    await tester.tap(find.text('Show'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.green[600]);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
  });

  testWidgets('AppSnackBar.showError uses red styling', (tester) async {
    await tester.pumpWidget(buildHarness(
      (context) => AppSnackBar.showError(context, 'Error'),
    ));

    await tester.tap(find.text('Show'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.red[600]);
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
  });

  testWidgets('AppSnackBar.showInfo uses blue styling', (tester) async {
    await tester.pumpWidget(buildHarness(
      (context) => AppSnackBar.showInfo(context, 'Info'),
    ));

    await tester.tap(find.text('Show'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.blue[600]);
    expect(find.byIcon(Icons.info), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
  });

  testWidgets('AppSnackBar.showWarning uses orange styling', (tester) async {
    await tester.pumpWidget(buildHarness(
      (context) => AppSnackBar.showWarning(context, 'Warning'),
    ));

    await tester.tap(find.text('Show'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.orange[600]);
    expect(find.byIcon(Icons.warning), findsOneWidget);
    expect(find.text('Warning'), findsOneWidget);
  });
}
