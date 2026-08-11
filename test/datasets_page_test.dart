import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/features/datasets/pages/datasets_page.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';

void main() {
  testWidgets('DatasetsPage lists datasets and toggles comparison selection', (
    tester,
  ) async {
    final previousStorage = storageService;
    storageService = InMemoryStorageService();
    addTearDown(() => storageService = previousStorage);

    final metas = [
      AssetDatasetMeta(
        path: 'assets/schedules/2024-2025_002.json',
        name: '2024-2025_002',
        courseCount: 10,
        year: '2024-2025',
        period: '2',
        updatedAt: DateTime(2024, 2, 1, 10, 0),
      ),
      AssetDatasetMeta(
        path: 'assets/schedules/2023-2024_001.json',
        name: '2023-2024_001',
        courseCount: 12,
        year: '2023-2024',
        period: '1',
        updatedAt: DateTime(2024, 1, 1, 10, 0),
      ),
    ];

    await storageService.setString(
      'active_dataset_path',
      'assets/schedules/2024-2025_002.json',
    );

    final container = ProviderContainer(
      overrides: [
        assetDatasetsProvider.overrideWith((ref) async => metas),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DatasetsPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dersler'), findsOneWidget);
    expect(find.text('2024-2025 2. dönem'), findsOneWidget);
    expect(find.text('2023-2024 1. dönem'), findsOneWidget);

    await tester.tap(find.text('Tümünü Seç'));
    await tester.pumpAndSettle();

    expect(
      container.read(selectedAssetCompareProvider),
      {
        'assets/schedules/2024-2025_002.json',
        'assets/schedules/2023-2024_001.json',
      },
    );

    await tester.tap(find.text('Tümünü Kaldır'));
    await tester.pumpAndSettle();

    expect(container.read(selectedAssetCompareProvider), isEmpty);
  });

  testWidgets('DatasetsPage changes active dataset', (tester) async {
    final previousStorage = storageService;
    storageService = InMemoryStorageService();
    addTearDown(() => storageService = previousStorage);

    final metas = [
      AssetDatasetMeta(
        path: 'assets/schedules/2024-2025_002.json',
        name: '2024-2025_002',
        courseCount: 10,
        year: '2024-2025',
        period: '2',
      ),
      AssetDatasetMeta(
        path: 'assets/schedules/2023-2024_001.json',
        name: '2023-2024_001',
        courseCount: 12,
        year: '2023-2024',
        period: '1',
      ),
    ];

    await storageService.setString(
      'active_dataset_path',
      'assets/schedules/2024-2025_002.json',
    );

    final container = ProviderContainer(
      overrides: [
        assetDatasetsProvider.overrideWith((ref) async => metas),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DatasetsPage()),
      ),
    );

    await tester.pumpAndSettle();

    final iconButtons = find.byTooltip('Veri seti olarak seç');
    expect(iconButtons, findsNWidgets(2));

    await tester.tap(iconButtons.at(1));
    await tester.pumpAndSettle();

    expect(
      container.read(activeAssetDatasetPathProvider),
      'assets/schedules/2023-2024_001.json',
    );
  });
}
