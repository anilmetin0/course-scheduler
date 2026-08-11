import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/features/course_selection/providers/course_providers.dart';
import 'package:scheduler/features/schedule/providers/saved_schedules_provider.dart';
import 'course_comparison_page.dart';

class DatasetsPage extends ConsumerWidget {
  const DatasetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetDatasetsProvider);
    final activePath = ref.watch(activeAssetDatasetPathProvider);
    final selectedSet = ref.watch(selectedAssetCompareProvider);
    final isCompact = MediaQuery.of(context).size.width < 900;

    // Get the most recent dataset path
    final mostRecentPath = ref.watch(mostRecentDatasetPathProvider);

    // Set the most recent as active if current path is empty or invalid
    if (mostRecentPath != null) {
      final isActivePathValid = assetsAsync.when(
        data: (assets) => assets.any((asset) => asset.path == activePath),
        loading: () => true, // Don't update while loading
        error: (error, stackTrace) => false,
      );

      // Only auto-set if path is completely empty (first time load)
      // Let the schedule page handle dataset selection when there are active courses
      if (activePath.isEmpty && !isActivePathValid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(activeAssetDatasetPathProvider.notifier).set(mostRecentPath);
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: isCompact
            ? const Text('Dersler')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo/logo.png', height: 32, width: 32),
                  const SizedBox(width: 8),
                  const Text('Dersler'),
                ],
              ),
        centerTitle: true,
      ),
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (assets) {
          // Collect all dataset paths for select-all logic
          final allPaths = assets.map((m) => m.path).toSet();
          final allSelected =
              allPaths.isNotEmpty && selectedSet.containsAll(allPaths);
          final updateLabel = datasetUpdateLabelFromAssets(assets);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Builder(
                builder: (context) {
                  final titleText = Text(
                    'Veri setleri (Güncelleme: $updateLabel)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  );
                  final compareControls = Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Karşılaştırma için seçin',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final notifier = ref.read(
                            selectedAssetCompareProvider.notifier,
                          );
                          if (allSelected) {
                            notifier.clear();
                          } else {
                            notifier.setAll(allPaths);
                          }
                        },
                        icon: Icon(
                          allSelected ? Icons.clear_all : Icons.select_all,
                        ),
                        label: Text(
                          allSelected ? 'Tümünü Kaldır' : 'Tümünü Seç',
                        ),
                      ),
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleText,
                        const SizedBox(height: 8),
                        compareControls,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      titleText,
                      compareControls,
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              ...assets.map(
                (m) => Card(
                  child: CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    value: selectedSet.contains(m.path),
                    onChanged: (checked) {
                      if (checked == true) {
                        ref
                            .read(selectedAssetCompareProvider.notifier)
                            .add(m.path);
                      } else {
                        ref
                            .read(selectedAssetCompareProvider.notifier)
                            .remove(m.path);
                      }
                    },
                    secondary: IconButton(
                      tooltip: 'Veri seti olarak seç',
                      icon: Icon(
                        activePath == m.path
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: activePath == m.path
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => _changeDataset(context, ref, m.path),
                    ),
                    title: Text(
                      _labelWithTerm(m),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('${m.courseCount} ders'),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              if (selectedSet.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              selectedSet.length == 1
                                  ? Icons.info_outline
                                  : Icons.compare_arrows,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedSet.length == 1
                                  ? 'Ders Detayları'
                                  : 'Ders Karşılaştırması',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedSet.length == 1
                              ? '1 dönem seçildi. Detaylı görünüm için tıklayın.'
                              : '${selectedSet.length} dönem seçildi. Detaylı karşılaştırma için tıklayın.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CourseComparisonPage(),
                                ),
                              );
                            },
                            icon: Icon(
                              selectedSet.length == 1
                                  ? Icons.visibility
                                  : Icons.analytics,
                            ),
                            label: Text(
                              selectedSet.length == 1
                                  ? 'Detayları Gör'
                                  : 'Detaylı Karşılaştırmayı Aç',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _labelWithTerm(AssetDatasetMeta m) {
  if (m.year != null && m.period != null) {
    return '${m.year} ${m.period}. dönem';
  }
  return m.name;
}

Future<void> _changeDataset(
  BuildContext context,
  WidgetRef ref,
  String newPath,
) async {
  final currentPath = ref.read(activeAssetDatasetPathProvider);
  final selectedCourses = ref.read(selectedCoursesProvider);
  final savedSchedules = ref.read(savedSchedulesProvider);

  // Eğer aynı dataset ise hiçbir şey yapma
  if (currentPath == newPath) return;

  // Eğer seçili dersler varsa uyarı göster
  if (selectedCourses.isNotEmpty) {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Veriseti Değiştirilecek'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Şu anda ${selectedCourses.length} ders seçili.'),
            const SizedBox(height: 8),
            const Text('Veriseti değiştirilirse:'),
            const SizedBox(height: 8),
            const Text('• Seçili dersler temizlenecek'),
            const Text('• Mevcut program tablosu sıfırlanacak'),
            const SizedBox(height: 8),
            const Text('Devam etmek istiyor musunuz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (shouldProceed != true) return;
  }

  // Eğer kaydedilmiş programlar varsa uyarı göster
  if (savedSchedules.isNotEmpty) {
    final currentDataset = ref.read(currentDatasetInfoProvider);
    final newDatasets = await ref.read(assetDatasetsProvider.future);
    if (!context.mounted) return;
    final newDataset = newDatasets.firstWhere((d) => d.path == newPath);

    final currentTerm = currentDataset != null
        ? _labelWithTerm(currentDataset)
        : 'Bilinmeyen dönem';
    final newTerm = _labelWithTerm(newDataset);

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dikkat!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${savedSchedules.length} adet kaydedilmiş programınız var.'),
            const SizedBox(height: 8),
            Text('Mevcut dönem: $currentTerm'),
            Text('Yeni dönem: $newTerm'),
            const SizedBox(height: 8),
            const Text('Bu programlar farklı dönem dersleri içerebilir.'),
            const SizedBox(height: 8),
            const Text('Yine de devam etmek istiyor musunuz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (shouldProceed != true) return;
  }

  // Veriseti değiştir ve seçili dersleri temizle
  ref.read(activeAssetDatasetPathProvider.notifier).set(newPath);
  if (selectedCourses.isNotEmpty) {
    ref.read(selectedCoursesProvider.notifier).clearAll();
  }
}
