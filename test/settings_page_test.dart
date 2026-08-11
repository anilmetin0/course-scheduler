import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduler/config/constants.dart';
import 'package:scheduler/core/config/app_info.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/features/about/pages/about_page.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/features/settings/pages/settings_page.dart';

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
        appVersionProvider.overrideWith((ref) async => '9.9.9'),
        assetDatasetsProvider.overrideWith(
          (ref) async => [
            AssetDatasetMeta(
              path: 'assets/schedules/2024-2025_001.json',
              name: '2024-2025_001',
              courseCount: 10,
              year: '2024-2025',
              period: '1',
            ),
          ],
        ),
      ],
    );
  }

  testWidgets('SettingsPage shows app info and version', (tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Uygulama Adı'), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Versiyon'), findsOneWidget);
    expect(find.text('9.9.9'), findsOneWidget);
  });

  testWidgets('SettingsPage navigates to AboutPage', (tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hakkında'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutPage), findsOneWidget);
  });
}
