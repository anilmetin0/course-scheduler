import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduler/app/theme/theme_provider.dart';
import 'package:scheduler/core/config/app_info.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/features/about/pages/about_page.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/shared/widgets/app_overflow_menu.dart';

void main() {
  late StorageService previousStorage;

  setUp(() {
    previousStorage = storageService;
    storageService = InMemoryStorageService();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    storageService = previousStorage;
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        appVersionProvider.overrideWith((ref) async => '1.0.0'),
        assetDatasetsProvider.overrideWith(
          (ref) async => [
            AssetDatasetMeta(
              path: 'assets/schedules/2024-2025_001.json',
              name: '2024-2025_001',
              courseCount: 10,
              year: '2024-2025',
              period: '1',
              updatedAt: DateTime(2024, 1, 1, 12, 0),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildHarness(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: const [AppOverflowMenu()]),
        ),
      ),
    );
  }

  testWidgets('AppOverflowMenu updates theme', (tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildHarness(container));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    final darkItem = find.byWidgetPredicate(
      (widget) =>
          widget is CheckedPopupMenuItem<Object> &&
          widget.value == AppThemeMode.dark,
    );
    await tester.tap(darkItem);
    await tester.pumpAndSettle();

    expect(container.read(themeProvider), AppThemeMode.dark);
  });

  testWidgets('AppOverflowMenu opens feedback dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = createContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildHarness(container));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geri Bildirim').hitTestable());
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('AppOverflowMenu navigates to AboutPage', (tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildHarness(container));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hakkında').hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(AboutPage), findsOneWidget);
  });
}
