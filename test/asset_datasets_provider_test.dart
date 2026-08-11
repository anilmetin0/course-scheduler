import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';

void main() {
  group('Asset datasets providers', () {
    late ProviderContainer container;
    late List<AssetDatasetMeta> datasets;
    late StorageService previousStorage;

    setUp(() {
      previousStorage = storageService;
      storageService = InMemoryStorageService();
      datasets = const [
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
          courseCount: 10,
          year: '2023-2024',
          period: '1',
        ),
      ];

      container = ProviderContainer(
        overrides: [
          assetDatasetsProvider.overrideWith((ref) async => datasets),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      storageService = previousStorage;
    });

    test('mostRecentDatasetPath returns most recent entry', () async {
      await container.read(assetDatasetsProvider.future);
      final path = container.read(mostRecentDatasetPathProvider);
      expect(path, 'assets/schedules/2024-2025_002.json');
    });

    test('currentDatasetInfo sets active path when empty', () async {
      await container.read(assetDatasetsProvider.future);

      final info = container.read(currentDatasetInfoProvider);
      expect(info?.path, 'assets/schedules/2024-2025_002.json');

      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(
        container.read(activeAssetDatasetPathProvider),
        'assets/schedules/2024-2025_002.json',
      );
    });

    test('SelectedAssetCompare add/remove/clear/setAll', () {
      final notifier = container.read(selectedAssetCompareProvider.notifier);

      notifier.add('a');
      notifier.add('b');
      expect(container.read(selectedAssetCompareProvider), {'a', 'b'});

      notifier.remove('a');
      expect(container.read(selectedAssetCompareProvider), {'b'});

      notifier.setAll({'x', 'y'});
      expect(container.read(selectedAssetCompareProvider), {'x', 'y'});

      notifier.clear();
      expect(container.read(selectedAssetCompareProvider), isEmpty);
    });
  });
}
