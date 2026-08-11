import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/shared/widgets/section_history_table.dart';

class CourseComparisonPage extends HookConsumerWidget {
  const CourseComparisonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSet = ref.watch(selectedAssetCompareProvider);
    final metasAsync = ref.watch(assetDatasetsProvider);
    final searchController = useTextEditingController();
    final searchQuery = useState<String>('');
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: isCompact
            ? Text(
                selectedSet.length == 1
                    ? 'Ders Detayları'
                    : 'Ders Karşılaştırma',
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo/logo.png', height: 32, width: 32),
                  const SizedBox(width: 8),
                  Text(
                    selectedSet.length == 1
                        ? 'Ders Detayları'
                        : 'Ders Karşılaştırma',
                  ),
                ],
              ),
        centerTitle: true,
        actions: [],
      ),
      body: selectedSet.isEmpty
          ? _buildEmptyState(context, ref)
          : _buildComparisonView(
              context,
              ref,
              selectedSet.toList(),
              metasAsync,
              searchController,
              searchQuery,
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Ders Karşılaştırması',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı dönemlerdeki ders istatistiklerini karşılaştırmak için en az 2 veri seti seçin veya tek bir veri setinin detaylarını görüntülemek için 1 veri seti seçin.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Veri Setleri Sayfasına Dön'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView(
    BuildContext context,
    WidgetRef ref,
    List<String> paths,
    AsyncValue<List<AssetDatasetMeta>> metasAsync,
    TextEditingController searchController,
    ValueNotifier<String> searchQuery,
  ) {
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: Future.wait(
        paths.map((p) => ref.read(assetDatasetCoursesProvider(p).future)),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final datasets = snapshot.data!;
        final Set<String> allCodes = {};
        final List<Map<String, _CodeAgg>> aggs = [];
        final Map<String, String> codeToName = {}; // Map course code to name
        final Map<String, String> codeToLecturer =
            {}; // Map course code to lecturer

        // Collect course names and lecturers while aggregating
        for (final courses in datasets) {
          // Extract course names and lecturers from this dataset
          for (final course in courses) {
            final code = (course['Code'] ?? '').toString();
            final name = (course['Name'] ?? '').toString();
            final lecturer = (course['Lecturer'] ?? '').toString();
            if (code.isNotEmpty &&
                name.isNotEmpty &&
                !codeToName.containsKey(code)) {
              codeToName[code] = name;
            }
            if (code.isNotEmpty &&
                lecturer.isNotEmpty &&
                !codeToLecturer.containsKey(code)) {
              codeToLecturer[code] = lecturer;
            }
          }

          final agg = _aggregateByCode(courses);
          aggs.add(agg);
          allCodes.addAll(agg.keys);
        }

        List<String> codes = allCodes.toList();
        final query = searchQuery.value.trim().toLowerCase();
        if (query.isNotEmpty) {
          codes = codes
              .where(
                (c) =>
                    c.toLowerCase().contains(query) ||
                    (codeToName[c]?.toLowerCase().contains(query) ?? false) ||
                    (codeToLecturer[c]?.toLowerCase().contains(query) ?? false),
              )
              .toList();
        }
        codes.sort();

        return Column(
          children: [
            _buildSearchBar(context, searchController, searchQuery),
            Expanded(
              child: _buildComparisonTable(
                context,
                codes,
                aggs,
                paths,
                metasAsync,
                codeToName,
                datasets,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<String> searchQuery,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText:
              'Ders kodu, adı veya öğretmen ara (örn: MATH 101, Statistics, Öğretmen Adı...)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    searchQuery.value = '';
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (value) {
          searchQuery.value = value;
        },
      ),
    );
  }

  Widget _buildComparisonTable(
    BuildContext context,
    List<String> codes,
    List<Map<String, _CodeAgg>> aggs,
    List<String> paths,
    AsyncValue<List<AssetDatasetMeta>> metasAsync,
    Map<String, String> codeToName,
    List<List<Map<String, dynamic>>> datasets,
  ) {
    return metasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (metas) {
        if (codes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Arama kriterlerinize uygun ders bulunamadı',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: codes.length,
          itemBuilder: (context, index) {
            final code = codes[index];
            return _buildCourseRow(
              context,
              code,
              aggs,
              paths,
              metas,
              codeToName,
              datasets,
            );
          },
        );
      },
    );
  }

  Widget _buildCourseRow(
    BuildContext context,
    String code,
    List<Map<String, _CodeAgg>> aggs,
    List<String> paths,
    List<AssetDatasetMeta> metas,
    Map<String, String> codeToName,
    List<List<Map<String, dynamic>>> datasets,
  ) {
    // Ders koduna göre her dönem için section listesi hazırla
    final courseData = <Map<String, dynamic>>[];
    for (int i = 0; i < paths.length; i++) {
      final meta = metas.firstWhere(
        (e) => e.path == paths[i],
        orElse: () => AssetDatasetMeta(
          path: paths[i],
          name: paths[i].split('/').last,
          courseCount: 0,
        ),
      );
      final sections = _sectionsForCode(datasets[i], code);
      courseData.add({'meta': meta, 'sections': sections, 'path': paths[i]});
    }

    // Sort courseData by year and period (most recent first)
    courseData.sort((a, b) {
      final metaA = a['meta'] as AssetDatasetMeta;
      final metaB = b['meta'] as AssetDatasetMeta;

      // First compare by year
      if (metaA.year != null && metaB.year != null) {
        final yearA = metaA.year!.replaceAll(
          '-',
          '',
        ); // "2024-2025" -> "20242025"
        final yearB = metaB.year!.replaceAll(
          '-',
          '',
        ); // "2024-2025" -> "20242025"
        final yearComparison = yearB.compareTo(yearA); // Reverse for descending
        if (yearComparison != 0) return yearComparison;
      }

      // Then compare by period (higher period = more recent)
      if (metaA.period != null && metaB.period != null) {
        final periodA = int.tryParse(metaA.period!) ?? 0;
        final periodB = int.tryParse(metaB.period!) ?? 0;
        return periodB.compareTo(periodA); // Reverse for descending
      }

      // If one has year/period and other doesn't, prioritize the one with year/period
      if (metaA.year != null && metaB.year == null) return -1;
      if (metaA.year == null && metaB.year != null) return 1;

      // Fallback to file name comparison (reverse for descending)
      return metaB.name.compareTo(metaA.name);
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ders başlığı
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getCourseColor(code),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (codeToName[code] != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      codeToName[code]!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Dönemler tablosu (paylaşılan widget)
            SectionHistoryTable(
              groups: [
                for (final data in courseData)
                  SectionTermGroup(
                    label: _formatDatasetLabel(data['meta'] as AssetDatasetMeta),
                    sections: (data['sections'] as List<_SectionAgg>)
                        .map((s) => SectionRowData(
                              section: s.section,
                              totalStudents: s.totalStudents,
                              successfull: s.successfull,
                              conditional: s.conditional,
                              unsuccessfull: s.unsuccessfull,
                              providedAvgText: s.providedAvgText,
                              lecturer: s.lecturer,
                            ))
                        .toList(),
                  ),
              ],
              courseCode: code,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDatasetLabel(AssetDatasetMeta meta) {
    if (meta.year != null && meta.period != null) {
      return '${meta.year} ${meta.period}. dönem';
    }
    return meta.name;
  }

  Color _getCourseColor(String code) {
    final hash = code.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
    ];
    return colors[hash.abs() % colors.length];
  }
}

// Existing _CodeAgg class from datasets_page.dart
class _CodeAgg {
  final int totalStudents;
  final int? successfull;
  final int? unsuccessfull;
  final int? conditional;
  final int? withdrawn;
  final String? providedAvgText;
  final String? lecturer;

  const _CodeAgg({
    required this.totalStudents,
    this.successfull,
    this.unsuccessfull,
    this.conditional,
    this.withdrawn,
    this.providedAvgText,
    this.lecturer,
  });
}

// Existing helper function from datasets_page.dart
Map<String, _CodeAgg> _aggregateByCode(List<Map<String, dynamic>> courses) {
  final Map<String, _CodeAgg> map = {};
  for (final c in courses) {
    final code = (c['Code'] ?? '').toString();
    if (code.isEmpty) continue;
    final students = int.tryParse((c['# of Students'] ?? '0').toString()) ?? 0;
    final successfull = int.tryParse(
      (c['Successfull'] ?? c['Successful'] ?? '').toString(),
    );
    final unsuccessfull = int.tryParse(
      (c['Unsuccessfull'] ?? c['Unsuccessful'] ?? '').toString(),
    );
    final conditional = int.tryParse((c['Conditional'] ?? '').toString());
    final withdrawn = int.tryParse((c['Withdrawn'] ?? '').toString());
    final avgProvidedText = _extractProvidedAverageText(c);
    final lecturer = (c['Lecturer'] ?? '').toString();
    final prev = map[code];
    if (prev == null) {
      map[code] = _CodeAgg(
        totalStudents: students,
        successfull: successfull,
        unsuccessfull: unsuccessfull,
        conditional: conditional,
        withdrawn: withdrawn,
        providedAvgText: avgProvidedText,
        lecturer: lecturer.isNotEmpty ? lecturer : null,
      );
    } else {
      map[code] = _CodeAgg(
        totalStudents: prev.totalStudents + students,
        successfull: (prev.successfull ?? 0) + (successfull ?? 0),
        unsuccessfull: (prev.unsuccessfull ?? 0) + (unsuccessfull ?? 0),
        conditional: (prev.conditional ?? 0) + (conditional ?? 0),
        withdrawn: (prev.withdrawn ?? 0) + (withdrawn ?? 0),
        providedAvgText: prev.providedAvgText ?? avgProvidedText,
        lecturer: prev.lecturer ?? (lecturer.isNotEmpty ? lecturer : null),
      );
    }
  }
  return map;
}

String? _extractProvidedAverageText(Map<String, dynamic> row) {
  final keys = [
    'Average',
    'Average Students',
    'Average # of Students',
    'Avg Students',
    'Students Avg',
    'Ortalama',
    'Ortalama Öğrenci',
    'Ortalama Ogrenci',
  ];
  for (final k in keys) {
    final v = row[k];
    if (v == null) continue;
    final s = v.toString();
    if (s.trim().isNotEmpty) return s;
  }
  return null;
}

// Section-based aggregation for a given course code
class _SectionAgg {
  final String section;
  final int totalStudents;
  final int? successfull;
  final int? unsuccessfull;
  final int? conditional;
  final int? withdrawn; // kept for possible future use
  final String? providedAvgText;
  final String? lecturer;
  const _SectionAgg({
    required this.section,
    required this.totalStudents,
    this.successfull,
    this.unsuccessfull,
    this.conditional,
    this.withdrawn,
    this.providedAvgText,
    this.lecturer,
  });
}

List<_SectionAgg> _sectionsForCode(List<Map<String, dynamic>> courses, String code) {
  final List<_SectionAgg> list = [];
  for (final c in courses) {
    final cc = (c['Code'] ?? '').toString();
    if (cc != code) continue;
    final section = (c['Section'] ?? '').toString();
    final students = int.tryParse((c['# of Students'] ?? '0').toString()) ?? 0;
    final successfull = int.tryParse((c['Successfull'] ?? c['Successful'] ?? '').toString());
    final unsuccessfull = int.tryParse((c['Unsuccessfull'] ?? c['Unsuccessful'] ?? '').toString());
    final conditional = int.tryParse((c['Conditional'] ?? '').toString());
    final withdrawn = int.tryParse((c['Withdrawn'] ?? '').toString());
    final avgProvidedText = _extractProvidedAverageText(c);
    final lecturer = (c['Lecturer'] ?? '').toString();
    list.add(
      _SectionAgg(
        section: section,
        totalStudents: students,
        successfull: successfull,
        unsuccessfull: unsuccessfull,
        conditional: conditional,
        withdrawn: withdrawn,
        providedAvgText: avgProvidedText,
        lecturer: lecturer.isNotEmpty ? lecturer : null,
      ),
    );
  }
  list.sort((a, b) => a.section.compareTo(b.section));
  return list;
}
