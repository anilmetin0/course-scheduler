import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduler/config/constants.dart';
import 'package:scheduler/core/config/app_info.dart';
import 'package:scheduler/features/about/pages/about_page.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AboutPage shows app name, version, and dataset update label', (
    tester,
  ) async {
    final datasets = [
      AssetDatasetMeta(
        path: 'assets/schedules/2023-2024_001.json',
        name: '2023-2024_001',
        courseCount: 10,
        year: '2023-2024',
        period: '1',
        updatedAt: DateTime(2024, 1, 2, 3, 4),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionProvider.overrideWith((ref) async => '1.2.3'),
          assetDatasetsProvider.overrideWith((ref) async => datasets),
        ],
        child: const MaterialApp(home: AboutPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('v1.2.3'), findsOneWidget);
    expect(find.text('Geliştirici'), findsWidgets); // title + card subtitle
  });
}
