import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/shared/widgets/section_history_table.dart';

class CourseHistorySection extends ConsumerWidget {
  final String code;
  final int? maxDatasets;
  const CourseHistorySection({
    super.key,
    required this.code,
    this.maxDatasets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSet = ref.watch(selectedAssetCompareProvider);
    final metasAsync = ref.watch(assetDatasetsProvider);

    return metasAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (metas) {
        // Determine dataset paths to use
        final List<String> paths = selectedSet.isNotEmpty
            ? selectedSet.toList()
            : (maxDatasets == null || maxDatasets! <= 0)
                ? metas.map((m) => m.path).toList()
                : metas.take(maxDatasets!).map((m) => m.path).toList();
        if (paths.isEmpty) return const SizedBox.shrink();

        return FutureBuilder<List<List<Map<String, dynamic>>>>(
          future: Future.wait(
            paths.map((p) => ref.read(assetDatasetCoursesProvider(p).future)),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              );
            }
            final datasets = snapshot.data!;

            // Build rows per dataset with meta
            final rows = <_HistoryRow>[];
            for (int i = 0; i < paths.length; i++) {
              final path = paths[i];
              final meta = metas.firstWhere(
                (e) => e.path == path,
                orElse: () => AssetDatasetMeta(
                  path: path,
                  name: path.split('/').last,
                  courseCount: 0,
                ),
              );
              final secs = _sectionsForCode(datasets[i], code);
              rows.add(_HistoryRow(meta: meta, sections: secs));
            }

            // Sort rows by recency similar to comparison page
            rows.sort((a, b) {
              final metaA = a.meta;
              final metaB = b.meta;
              if (metaA.year != null && metaB.year != null) {
                final yearA = metaA.year!.replaceAll('-', '');
                final yearB = metaB.year!.replaceAll('-', '');
                final yc = yearB.compareTo(yearA);
                if (yc != 0) return yc;
              }
              if (metaA.period != null && metaB.period != null) {
                final pA = int.tryParse(metaA.period!) ?? 0;
                final pB = int.tryParse(metaB.period!) ?? 0;
                return pB.compareTo(pA);
              }
              if (metaA.year != null && metaB.year == null) return -1;
              if (metaA.year == null && metaB.year != null) return 1;
              return metaB.name.compareTo(metaA.name);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geçmiş Dönem Bilgileri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SectionHistoryTable(
                  groups: [
                    for (final r in rows)
                      SectionTermGroup(
                        label: _formatDatasetLabel(r.meta),
                        sections: r.sections
                            ?.map(
                              (s) => SectionRowData(
                                section: s.section,
                                totalStudents: s.totalStudents,
                                successfull: s.successfull,
                                conditional: s.conditional,
                                unsuccessfull: s.unsuccessfull,
                                providedAvgText: s.providedAvgText,
                                lecturer: s.lecturer,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                  courseCode: code,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HistoryRow {
  final AssetDatasetMeta meta;
  final List<_SectionAgg>? sections;
  _HistoryRow({required this.meta, required this.sections});
}

class _SectionAgg {
  final String section;
  final int totalStudents;
  final int? successfull;
  final int? unsuccessfull;
  final int? conditional;
  final String? providedAvgText;
  final String? lecturer;
  const _SectionAgg({
    required this.section,
    required this.totalStudents,
    this.successfull,
    this.unsuccessfull,
    this.conditional,
    this.providedAvgText,
    this.lecturer,
  });
}

List<_SectionAgg> _sectionsForCode(
  List<Map<String, dynamic>> courses,
  String code,
) {
  final List<_SectionAgg> list = [];
  for (final row in courses) {
    final c = (row['Code'] ?? '').toString();
    if (c != code) continue;
    final section = (row['Section'] ?? '').toString();
    final students =
        int.tryParse((row['# of Students'] ?? '0').toString()) ?? 0;
    final successfull = int.tryParse(
      (row['Successfull'] ?? row['Successful'] ?? '').toString(),
    );
    final unsuccessfull = int.tryParse(
      (row['Unsuccessfull'] ?? row['Unsuccessful'] ?? '').toString(),
    );
    final conditional = int.tryParse((row['Conditional'] ?? '').toString());
    final avgText = _extractProvidedAverageText(row);
    final lecturer = (row['Lecturer'] ?? '').toString();
    list.add(
      _SectionAgg(
        section: section,
        totalStudents: students,
        successfull: successfull,
        unsuccessfull: unsuccessfull,
        conditional: conditional,
        providedAvgText: avgText,
        lecturer: lecturer.isNotEmpty ? lecturer : null,
      ),
    );
  }
  // Sort by section label for stable order
  list.sort((a, b) => a.section.compareTo(b.section));
  return list;
}

String _formatDatasetLabel(AssetDatasetMeta meta) {
  if (meta.year != null && meta.period != null) {
    return '${meta.year} ${meta.period}. dönem';
  }
  return meta.name;
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
