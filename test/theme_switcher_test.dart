import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/app/theme/theme_provider.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/shared/widgets/theme_switcher.dart';

void main() {
  testWidgets('ThemeSwitcher selects dark theme', (tester) async {
    final previousStorage = storageService;
    storageService = InMemoryStorageService();
    addTearDown(() => storageService = previousStorage);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ThemeSwitcher()),
        ),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<AppThemeMode>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Karanlık Tema'));
    await tester.pumpAndSettle();

    expect(container.read(themeProvider), AppThemeMode.dark);
  });
}
