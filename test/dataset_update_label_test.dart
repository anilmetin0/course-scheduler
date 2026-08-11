import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';

void main() {
  test('datasetUpdateLabelFromAssets picks latest updatedAt', () {
    final datasets = [
      AssetDatasetMeta(
        path: 'assets/schedules/2023-2024_001.json',
        name: '2023-2024_001',
        courseCount: 1,
        updatedAt: DateTime(2024, 1, 1, 10, 0),
      ),
      AssetDatasetMeta(
        path: 'assets/schedules/2024-2025_001.json',
        name: '2024-2025_001',
        courseCount: 1,
        updatedAt: DateTime(2024, 2, 3, 9, 30),
      ),
    ];

    final label = datasetUpdateLabelFromAssets(datasets);

    expect(label, '03.02.2024 09:30');
  });
}
