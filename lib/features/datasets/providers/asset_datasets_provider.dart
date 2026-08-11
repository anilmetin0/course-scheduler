import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scheduler/core/services/storage_service.dart';

part 'asset_datasets_provider.g.dart';

class AssetDatasetMeta {
  final String path; // e.g., assets/schedules/courses.json
  final String name; // file name
  final int courseCount;
  final String? year;
  final String? period;
  final DateTime? updatedAt;

  const AssetDatasetMeta({
    required this.path,
    required this.name,
    required this.courseCount,
    this.year,
    this.period,
    this.updatedAt,
  });
}

DateTime? _parseDatasetTimestamp(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return _parseEpoch(raw);
  if (raw is double) return _parseEpoch(raw.round());
  if (raw is String) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final match = RegExp(
      r'^(\d{2})\.(\d{2})\.(\d{4})(?:\s+(\d{2}):(\d{2}))?$',
    ).firstMatch(value);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4) ?? '0');
      final minute = int.parse(match.group(5) ?? '0');
      return DateTime(year, month, day, hour, minute);
    }
  }
  return null;
}

DateTime _parseEpoch(int value) {
  final isMillis = value > 1000000000000;
  return DateTime.fromMillisecondsSinceEpoch(
    isMillis ? value : value * 1000,
  );
}

// Discover JSON assets via AssetManifest
@Riverpod(keepAlive: true)
Future<List<AssetDatasetMeta>> assetDatasets(Ref ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final paths = manifest.listAssets().where((k) {
    final lower = k.toLowerCase();
    if (!lower.startsWith('assets/schedules/')) return false;
    if (!lower.endsWith('.json')) return false;
    if (lower.startsWith('assets/i18n/')) return false;
    // Exclude example datasets from picker
    final fileName = lower.split('/').last;
    if (fileName.startsWith('example')) return false;
    return true;
  }).toList()..sort();

  final metas = <AssetDatasetMeta>[];
  for (final path in paths) {
    try {
      final text = await rootBundle.loadString(path);
      final data = json.decode(text) as Map<String, dynamic>;
      final list = (data['courses'] as List<dynamic>? ?? const []);
      final metadata = data['metadata'];
      DateTime? updatedAt;
      if (metadata is Map<String, dynamic>) {
        final rawUpdatedAt =
            metadata['updated_at'] ??
            metadata['generated_at'] ??
            metadata['generatedAt'];
        updatedAt = _parseDatasetTimestamp(rawUpdatedAt);
      }

      // Parse filename like "2024-2025_001.json" to extract year and period
      final fileName = path.split('/').last.replaceAll('.json', '');
      String? year;
      String? period;

      final match = RegExp(r'^(\d{4}-\d{4})_(\d{3})$').firstMatch(fileName);
      if (match != null) {
        year = match.group(1); // e.g., "2024-2025"
        final periodCode = match.group(2)!; // e.g., "001"
        final periodNum = int.tryParse(periodCode);
        if (periodNum != null) {
          period = periodNum.toString(); // Convert "001" to "1"
        }
      } else {
        // Fallback: try to get from first course data
        if (list.isNotEmpty) {
          final first = Map<String, dynamic>.from(list.first as Map);
          year = first['Year']?.toString();
          period = first['Period']?.toString();
          if (period != null && period.length > 1) {
            final n = int.tryParse(period);
            if (n != null) period = n.toString();
          }
        }
      }

      metas.add(
        AssetDatasetMeta(
          path: path,
          name: fileName,
          courseCount: list.length,
          year: year,
          period: period,
          updatedAt: updatedAt,
        ),
      );
    } catch (_) {
      final fileName = path.split('/').last.replaceAll('.json', '');
      metas.add(AssetDatasetMeta(path: path, name: fileName, courseCount: 0));
    }
  }

  // Sort datasets by year and period (most recent first)
  metas.sort((a, b) {
    // First compare by year
    if (a.year != null && b.year != null) {
      final yearA = a.year!.replaceAll('-', ''); // "2024-2025" -> "20242025"
      final yearB = b.year!.replaceAll('-', ''); // "2024-2025" -> "20242025"
      final yearComparison = yearB.compareTo(yearA); // Reverse for descending
      if (yearComparison != 0) return yearComparison;
    }

    // Then compare by period (higher period = more recent)
    if (a.period != null && b.period != null) {
      final periodA = int.tryParse(a.period!) ?? 0;
      final periodB = int.tryParse(b.period!) ?? 0;
      return periodB.compareTo(periodA); // Reverse for descending
    }

    // If one has year/period and other doesn't, prioritize the one with year/period
    if (a.year != null && b.year == null) return -1;
    if (a.year == null && b.year != null) return 1;

    // Fallback to file name comparison (reverse for descending)
    return b.name.compareTo(a.name);
  });

  return metas;
}

const _kKeyActiveScheduleId = 'active_schedule_id';
const _kKeySavedSchedulesItems = 'saved_schedules_items';
const _kKeyActiveDatasetPath = 'active_dataset_path';

// Active JSON asset path (automatically set to the most recent dataset)
@Riverpod(keepAlive: true)
class ActiveAssetDatasetPath extends _$ActiveAssetDatasetPath {
  bool _isInitializing = false;

  @override
  String build() {
    // Her build'de storage'dan yükleme yap
    // Bu sayede sayfa yenilendiğinde doğru değer gelir
    _loadFromStorage();
    return '';
  }

  Future<void> _loadFromStorage() async {
    // Eğer zaten yükleme yapılıyorsa tekrar yapma
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // Önce doğrudan kaydedilmiş dataset path'i kontrol et
      final savedPath = await storageService.getString(_kKeyActiveDatasetPath);
      if (savedPath != null && savedPath.isNotEmpty) {
        // Path'in hala geçerli olup olmadığını kontrol et
        final datasets = await ref.read(assetDatasetsProvider.future);
        final pathExists = datasets.any((d) => d.path == savedPath);
        if (pathExists) {
          if (state != savedPath) {
            state = savedPath;
          }
          _isInitializing = false;
          return;
        }
      }

      // Kaydedilmiş path yoksa veya geçersizse, aktif schedule'dan al
      final scheduleId = await storageService.getString(_kKeyActiveScheduleId);
      if (scheduleId != null && scheduleId.isNotEmpty) {
        final schedulesRaw = await storageService.getString(
          _kKeySavedSchedulesItems,
        );
        if (schedulesRaw != null && schedulesRaw.isNotEmpty) {
          try {
            final decoded = json.decode(schedulesRaw) as List<dynamic>;
            final scheduleData = decoded
                .cast<Map<String, dynamic>?>()
                .firstWhere((s) => s?['id'] == scheduleId, orElse: () => null);

            if (scheduleData != null) {
              final datasetPath = scheduleData['datasetPath']?.toString();
              if (datasetPath != null && datasetPath.isNotEmpty) {
                if (state != datasetPath) {
                  state = datasetPath;
                  // Path'i kaydet
                  await storageService.setString(
                    _kKeyActiveDatasetPath,
                    datasetPath,
                  );
                }
                _isInitializing = false;
                return;
              }
            }
          } catch (_) {
            // JSON parse hatası - devam et
          }
        }
      }

      // Hiçbir şey bulunamadıysa en güncel dataset'i seç
      final datasets = await ref.read(assetDatasetsProvider.future);
      if (datasets.isNotEmpty && state.isEmpty) {
        state = datasets.first.path;
        await storageService.setString(
          _kKeyActiveDatasetPath,
          datasets.first.path,
        );
      }
    } finally {
      _isInitializing = false;
    }
  }

  void set(String path) {
    state = path;
    // Path değiştiğinde storage'a kaydet
    storageService.setString(_kKeyActiveDatasetPath, path);
  }
}

// Current dataset info provider
@riverpod
AssetDatasetMeta? currentDatasetInfo(Ref ref) {
  final datasets = ref.watch(assetDatasetsProvider);
  final activePath = ref.watch(activeAssetDatasetPathProvider);

  return datasets.when(
    data: (list) {
      if (list.isEmpty) return null;

      // ActiveAssetDatasetPath henüz initialize olmadıysa,
      // geçici olarak en güncel dataset'i göster (ama state'i değiştirme)
      if (activePath.isEmpty) {
        // State'i değiştirmeden en güncel dataset'i döndür
        // ActiveAssetDatasetPath kendi _initializeFromActiveSchedule metodunda
        // doğru değeri ayarlayacak
        return list.first;
      }

      // Find the dataset with the active path
      try {
        final result = list.firstWhere((dataset) => dataset.path == activePath);
        return result;
      } catch (e) {
        // Path bulunamadıysa en güncel dataset'e geç
        Future.microtask(() {
          ref
              .read(activeAssetDatasetPathProvider.notifier)
              .set(list.first.path);
        });

        return list.first;
      }
    },
    loading: () => null,
    error: (error, stackTrace) => null,
  );
}

// Provider to automatically set the most recent dataset as active
@riverpod
String? mostRecentDatasetPath(Ref ref) {
  final datasetsAsync = ref.watch(assetDatasetsProvider);

  return datasetsAsync.when(
    data: (datasets) {
      if (datasets.isEmpty) return null;

      // Sort datasets by year and period to find the most recent
      final sortedDatasets = List<AssetDatasetMeta>.from(datasets);
      sortedDatasets.sort((a, b) {
        // First compare by year
        if (a.year != null && b.year != null) {
          final yearA = a.year!.replaceAll(
            '-',
            '',
          ); // "2024-2025" -> "20242025"
          final yearB = b.year!.replaceAll(
            '-',
            '',
          ); // "2024-2025" -> "20242025"
          final yearComparison = yearB.compareTo(
            yearA,
          ); // Reverse for descending
          if (yearComparison != 0) return yearComparison;
        }

        // Then compare by period (higher period = more recent)
        if (a.period != null && b.period != null) {
          final periodA = int.tryParse(a.period!) ?? 0;
          final periodB = int.tryParse(b.period!) ?? 0;
          return periodB.compareTo(periodA); // Reverse for descending
        }

        // Fallback to file name comparison
        return b.name.compareTo(a.name);
      });

      return sortedDatasets.first.path;
    },
    loading: () => null,
    error: (error, stackTrace) => null,
  );
}

// Selected asset JSONs for comparison
@Riverpod(keepAlive: true)
class SelectedAssetCompare extends _$SelectedAssetCompare {
  @override
  Set<String> build() => <String>{};

  void add(String path) {
    state = {...state, path};
  }

  void remove(String path) {
    state = Set<String>.from(state)..remove(path);
  }

  void clear() {
    state = <String>{};
  }

  void setAll(Set<String> paths) {
    state = paths;
  }
}

// Yeni dönem uyarısı için kontrol provider'ı
// Aktif dataset'in en güncel olup olmadığını kontrol eder
@riverpod
NewerDatasetInfo? newerDatasetAvailable(Ref ref) {
  final datasetsAsync = ref.watch(assetDatasetsProvider);
  final activePath = ref.watch(activeAssetDatasetPathProvider);

  return datasetsAsync.when(
    data: (datasets) {
      if (datasets.isEmpty || activePath.isEmpty) return null;

      // En güncel dataset (liste zaten sıralı)
      final mostRecent = datasets.first;

      // Aktif dataset
      final activeDataset = datasets.cast<AssetDatasetMeta?>().firstWhere(
        (d) => d?.path == activePath,
        orElse: () => null,
      );

      if (activeDataset == null) return null;

      // Eğer aktif dataset en güncel değilse, bilgi döndür
      if (mostRecent.path != activePath) {
        return NewerDatasetInfo(
          currentDataset: activeDataset,
          newerDataset: mostRecent,
        );
      }

      return null;
    },
    loading: () => null,
    error: (_, _) => null,
  );
}

// Yeni dönem bilgisi için yardımcı sınıf
class NewerDatasetInfo {
  final AssetDatasetMeta currentDataset;
  final AssetDatasetMeta newerDataset;

  const NewerDatasetInfo({
    required this.currentDataset,
    required this.newerDataset,
  });
}

// Yeni dönem uyarısının gösterilip gösterilmeyeceğini kontrol eden provider
// Kullanıcı "Hayır" dedikten sonra tekrar gösterilmemesi için
const _kKeyNewerDatasetDismissed = 'newer_dataset_dismissed';

@Riverpod(keepAlive: true)
class NewerDatasetDismissed extends _$NewerDatasetDismissed {
  @override
  String? build() {
    _loadFromStorage();
    return null;
  }

  Future<void> _loadFromStorage() async {
    final dismissed = await storageService.getString(
      _kKeyNewerDatasetDismissed,
    );
    if (dismissed != null && dismissed.isNotEmpty) {
      state = dismissed;
    }
  }

  void dismiss(String newerDatasetPath) {
    state = newerDatasetPath;
    storageService.setString(_kKeyNewerDatasetDismissed, newerDatasetPath);
  }

  void reset() {
    state = null;
    storageService.remove(_kKeyNewerDatasetDismissed);
  }
}

// Load raw courses list from a JSON asset path
@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> assetDatasetCourses(
  Ref ref,
  String path,
) async {
  final text = await rootBundle.loadString(path);
  final data = json.decode(text) as Map<String, dynamic>;
  final list = (data['courses'] as List<dynamic>? ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  return list;
}

String datasetUpdateLabelFromAssets(
  List<AssetDatasetMeta> datasets, {
  String fallbackLabel = 'Bilinmiyor',
}) {
  DateTime? latest;
  for (final dataset in datasets) {
    final updatedAt = dataset.updatedAt;
    if (updatedAt == null) continue;
    if (latest == null || updatedAt.isAfter(latest)) {
      latest = updatedAt;
    }
  }

  if (latest == null) return fallbackLabel;
  return _formatDatasetUpdateDate(latest);
}

String _formatDatasetUpdateDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}.${twoDigits(local.month)}.${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
