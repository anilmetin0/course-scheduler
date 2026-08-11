// Course selection page
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scheduler/features/course_selection/providers/course_providers.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/models/saved_schedule.dart';
import 'package:scheduler/features/datasets/pages/datasets_page.dart';
import 'package:scheduler/features/schedule/providers/saved_schedules_provider.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/config/constants.dart';
import 'package:scheduler/core/services/analytics_service.dart';
import 'package:scheduler/core/services/analytics_data_service.dart';
import 'package:scheduler/core/services/metrics_service.dart';
import 'package:scheduler/shared/widgets/app_snackbar.dart';
import 'package:scheduler/shared/widgets/course_detail_overlay.dart';
import 'package:flutter/services.dart';
import 'package:scheduler/core/utils/export_format.dart';

class CourseSelectionPage extends HookConsumerWidget {
  const CourseSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final courseGroups = ref.watch(courseGroupsProvider);
    final selectedCourses = ref.watch(selectedCoursesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchController = useTextEditingController();
    final isCompact = MediaQuery.of(context).size.width < 900;

    useEffect(() {
      if (searchController.text != searchQuery) {
        searchController.value = TextEditingValue(
          text: searchQuery,
          selection: TextSelection.collapsed(offset: searchQuery.length),
        );
      }
      return null;
    }, [searchQuery]);
    final scheduleTable = ref.watch(activeScheduleProvider);
    final combinations = ref.watch(scheduleCombinationsProvider);
    final activeIndex = ref.watch(activeCombinationIndexProvider);
    final allowConflicts = ref.watch(allowConflictsProvider);
    final minFreeDays = ref.watch(minFreeDaysProvider);
    final hoveredGroup = useState<CourseGroup?>(null);
    final hoveredCourse = useState<Course?>(null);
    final lastConflictKey = useRef<String?>(null);
    final presentCourseIds = <String>{};
    for (final dayMap in scheduleTable.values) {
      for (final coursesAtTime in dayMap.values) {
        for (final course in coursesAtTime) {
          presentCourseIds.add(course.id);
        }
      }
    }
    final hoveredPreviewSource = hoveredCourse.value != null
        ? [hoveredCourse.value!]
        : (hoveredGroup.value?.sections ?? const <Course>[]);
    final hoveredPreviewCourses = hoveredPreviewSource
        .where((course) => !presentCourseIds.contains(course.id))
        .toList();

    useEffect(() {
      if (selectedCourses.isEmpty) {
        lastConflictKey.value = null;
        return null;
      }
      if (!allowConflicts && combinations.isEmpty) {
        final keys = selectedCourses
            .map((course) => course.section.isNotEmpty
                ? '${course.code}-${course.section}'
                : course.code)
            .toList()
          ..sort();
        final signature = keys.join('|');
        if (lastConflictKey.value != signature) {
          lastConflictKey.value = signature;
          unawaited(
            AnalyticsService().logConflictDetected(
              conflictCount: selectedCourses.length,
            ),
          );
          unawaited(
            AnalyticsDataService().logConflictDetected(
              courses: selectedCourses,
              conflictCount: selectedCourses.length,
            ),
          );
          unawaited(MetricsService().logConflictForCourses(selectedCourses));
        }
      } else {
        lastConflictKey.value = null;
      }
      return null;
    }, [selectedCourses, combinations, allowConflicts]);

    final scaffold = Scaffold(
      appBar: AppBar(
        title: isCompact
            ? const Text('Ders Seçimi')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo/logo.png', height: 32, width: 32),
                  const SizedBox(width: 8),
                  const Text('Ders Seçimi'),
                ],
              ),
        centerTitle: true,
        actions: isCompact
            ? [
                PopupMenuButton<_CourseSelectionMenuAction>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) async {
                    switch (action) {
                      case _CourseSelectionMenuAction.export:
                        if (combinations.isEmpty) return;
                        final idx = ref.read(activeCombinationIndexProvider);
                        final safeIndex =
                            idx < combinations.length ? idx : 0;
                        final exportCourses = combinations[safeIndex];
                        await _showExportDialog(context, exportCourses);
                        break;
                      case _CourseSelectionMenuAction.save:
                        await _saveCurrentSchedule(context, ref);
                        break;
                      case _CourseSelectionMenuAction.clear:
                        ref.read(selectedCoursesProvider.notifier).clearAll();
                        break;
                      case _CourseSelectionMenuAction.datasets:
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DatasetsPage(),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _CourseSelectionMenuAction.export,
                      enabled: combinations.isNotEmpty,
                      child: Row(
                        children: const [
                          Icon(Icons.ios_share, size: 18),
                          SizedBox(width: 8),
                          Text('Dışarı aktar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: _CourseSelectionMenuAction.save,
                      child: Row(
                        children: [
                          Icon(Icons.save_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Programı Kaydet'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _CourseSelectionMenuAction.clear,
                      enabled: selectedCourses.isNotEmpty,
                      child: Row(
                        children: const [
                          Icon(Icons.clear_all, size: 18),
                          SizedBox(width: 8),
                          Text('Tümünü Temizle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: _CourseSelectionMenuAction.datasets,
                      child: Row(
                        children: [
                          Icon(Icons.library_books_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Dersler'),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'Dışarı aktar',
                  onPressed: combinations.isNotEmpty
                      ? () {
                          final idx = ref.read(activeCombinationIndexProvider);
                          final safeIndex =
                              idx < combinations.length ? idx : 0;
                          final exportCourses = combinations[safeIndex];
                          _showExportDialog(context, exportCourses);
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.save_outlined),
                  tooltip: 'Programı Kaydet',
                  onPressed: () async {
                    await _saveCurrentSchedule(context, ref);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: selectedCourses.isNotEmpty
                      ? () {
                          ref
                              .read(selectedCoursesProvider.notifier)
                              .clearAll();
                        }
                      : null,
                  tooltip: 'Tümünü Temizle',
                ),
                IconButton(
                  tooltip: 'Dersler',
                  icon: const Icon(Icons.library_books_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DatasetsPage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
              ],
        bottom: isCompact
            ? const TabBar(
                tabs: [
                  Tab(text: 'Dersler'),
                  Tab(text: 'Program'),
                ],
              )
            : null,
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Dersler yüklenirken hata oluştu'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        data: (_) {
          final courseListPanel = Column(
            children: [
              // Sol taraf - Ders listesi
                  // Seçilen dersler - En üstte (Katlanabilir)
                  if (selectedCourses.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: const PageStorageKey('selected-courses'),
                          initiallyExpanded: selectedCourses.length <= 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            8,
                            8,
                            8,
                            0,
                          ),
                          leading: Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          title: Text(
                            'Seçilen Dersler (${selectedCourses.length})',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          children: [
                            Builder(
                              builder: (context) {
                                // Seçilen dersleri ders koduna göre grupla
                                final Map<String, List<Course>> selectedByCode =
                                    {};
                                for (final c in selectedCourses) {
                                  (selectedByCode[c.code] ??= <Course>[]).add(
                                    c,
                                  );
                                }

                                final notifier = ref.read(
                                  selectedCoursesProvider.notifier,
                                );

                                return Column(
                                  children: selectedByCode.entries.map((entry) {
                                    final code = entry.key;
                                    final list = entry.value;
                                    final first = list.first;

                                    // Seçilen section'ların renklerini karıştır
                                    final color = _calculateMixedColor(
                                      list
                                          .map((course) {
                                            final courseKey =
                                                course.section.isNotEmpty
                                                ? '${course.code}-${course.section}'
                                                : course.code;
                                            return ref
                                                .read(
                                                  courseColorsProvider.notifier,
                                                )
                                                .getColorForCourse(courseKey);
                                          })
                                          .toList()
                                          .cast<Color>(),
                                    );

                                    return Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '$code - ${first.name}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () => notifier
                                                      .removeCourses(list),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Container(
                                                    width: 16,
                                                    height: 16,
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(
                                                        alpha: .9,
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: list.map((course) {
                                                final label =
                                                    course.section.isNotEmpty
                                                    ? course.section
                                                    : course.code;
                                                final courseKey =
                                                    course.section.isNotEmpty
                                                    ? '${course.code}-${course.section}'
                                                    : course.code;
                                                final chipColor = ref
                                                    .read(
                                                      courseColorsProvider
                                                          .notifier,
                                                    )
                                                    .getColorForCourse(
                                                      courseKey,
                                                    );
                                                return Hero(
                                                  tag: 'course_chip_$courseKey',
                                                  child: Material(
                                                    type: MaterialType
                                                        .transparency,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: chipColor
                                                            .withValues(
                                                              alpha: .85,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                  8,
                                                                ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              label,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              softWrap: false,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          GestureDetector(
                                                            onTap: () =>
                                                                notifier
                                                                    .removeCourse(
                                                                      course,
                                                                    ),
                                                            child: const Icon(
                                                              Icons.close,
                                                              color:
                                                                  Colors.white,
                                                              size: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Arama ve filtreler
                  Container(
                    key: const ValueKey('course_search_section'),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Column(
                      children: [
                        // Arama kutusu
                        Consumer(
                          builder: (context, ref, child) {
                            final currentDataset = ref.watch(
                              currentDatasetInfoProvider,
                            );
                            String termHint = '';
                            if (currentDataset?.year != null &&
                                currentDataset?.period != null) {
                              termHint =
                                  ' (${currentDataset!.year} ${currentDataset.period}. dönem)';
                            } else if (currentDataset?.name != null) {
                              termHint = ' (${currentDataset!.name})';
                            }

                            return TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Ders ara...$termHint',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          searchController.clear();
                                          ref
                                              .read(
                                                searchQueryProvider.notifier,
                                              )
                                              .update('');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (value) {
                                ref
                                    .read(searchQueryProvider.notifier)
                                    .update(value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),

                        // Çakışma ve boş gün filtreleri
                        Builder(
                          builder: (context) {
                            final freeDaysField =
                                DropdownButtonFormField<int?>(
                                  initialValue: minFreeDays,
                                  decoration: InputDecoration(
                                    labelText: 'Boş gün',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  items: const [
                                    DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Yok'),
                                    ),
                                    DropdownMenuItem<int?>(
                                      value: 1,
                                      child: Text('1'),
                                    ),
                                    DropdownMenuItem<int?>(
                                      value: 2,
                                      child: Text('2'),
                                    ),
                                    DropdownMenuItem<int?>(
                                      value: 3,
                                      child: Text('3'),
                                    ),
                                    DropdownMenuItem<int?>(
                                      value: 4,
                                      child: Text('4'),
                                    ),
                                  ],
                                  onChanged: (val) => ref
                                      .read(minFreeDaysProvider.notifier)
                                      .set(val),
                                );
                            final conflictsToggle = SwitchListTile.adaptive(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              value: allowConflicts,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Çakışmaya izin ver'),
                              onChanged: (val) => ref
                                  .read(allowConflictsProvider.notifier)
                                  .set(val),
                            );

                            if (isCompact) {
                              return Column(
                                children: [
                                  freeDaysField,
                                  const SizedBox(height: 8),
                                  conflictsToggle,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: freeDaysField),
                                const SizedBox(width: 8),
                                Expanded(child: conflictsToggle),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Ders listesi
                  Expanded(
                    child: courseGroups.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Ders bulunamadı',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            itemCount: courseGroups.length,
                            itemBuilder: (context, index) {
                              final group = courseGroups[index];

                              final selectedCoursesList = ref.watch(
                                selectedCoursesProvider,
                              );
                              final selectedSections = group.sections
                                  .where((c) => selectedCoursesList.contains(c))
                                  .toList();
                              final selectedCount = selectedSections.length;

                              // Grup rengini hesapla
                              final Color groupColor;
                              if (selectedSections.isEmpty) {
                                // Hiç seçili section yok ise tüm section'ların renklerini karıştır
                                groupColor = _calculateMixedColor(
                                  group.sections
                                      .map((section) {
                                        final courseKey =
                                            section.section.isNotEmpty
                                            ? '${section.code}-${section.section}'
                                            : section.code;
                                        return ref
                                            .read(courseColorsProvider.notifier)
                                            .getColorForCourse(courseKey);
                                      })
                                      .toList()
                                      .cast<Color>(),
                                );
                              } else {
                                // Seçili section'ların renklerini karıştır
                                groupColor = _calculateMixedColor(
                                  selectedSections
                                      .map((section) {
                                        final courseKey =
                                            section.section.isNotEmpty
                                            ? '${section.code}-${section.section}'
                                            : section.code;
                                        return ref
                                            .read(courseColorsProvider.notifier)
                                            .getColorForCourse(courseKey);
                                      })
                                      .toList()
                                      .cast<Color>(),
                                );
                              }

                              return MouseRegion(
                                onEnter: (_) {
                                  hoveredCourse.value = null;
                                  hoveredGroup.value =
                                      group.sections.isNotEmpty ? group : null;
                                },
                                onExit: (_) {
                                  if (hoveredGroup.value?.code == group.code) {
                                    hoveredGroup.value = null;
                                  }
                                  if (hoveredCourse.value?.code ==
                                      group.code) {
                                    hoveredCourse.value = null;
                                  }
                                },
                                child: Card(
                                  shape: selectedCount > 0
                                      ? RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: groupColor.withValues(
                                              alpha: 0.7,
                                            ),
                                            width: 1.0,
                                          ),
                                        )
                                      : RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      collapsedShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      key: PageStorageKey<String>(
                                        'course-group-${group.code}',
                                      ),
                                      leading: HookBuilder(
                                        builder: (ctx) {
                                          final hovered = useState(false);
                                          final firstCourse =
                                              selectedSections.isNotEmpty
                                              ? selectedSections.first
                                              : (group.sections.isNotEmpty
                                                    ? group.sections.first
                                                    : null);
                                          final heroTag =
                                              'course-group-hero-${firstCourse?.id ?? group.code}';
                                          final avatar = CircleAvatar(
                                            backgroundColor: groupColor,
                                            radius: 16,
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 120,
                                              ),
                                              transitionBuilder: (c, anim) =>
                                                  FadeTransition(
                                                    opacity: anim,
                                                    child: c,
                                                  ),
                                              child: hovered.value
                                                  ? const Icon(
                                                      Icons.info_outline,
                                                      key: ValueKey('info'),
                                                      size: 16,
                                                      color: Colors.white,
                                                    )
                                                  : Text(
                                                      group.code
                                                          .split(' ')[0]
                                                          .substring(0, 2)
                                                          .toUpperCase(),
                                                      key:
                                                          const ValueKey(
                                                            'text',
                                                          ),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                            ),
                                          );
                                          return MouseRegion(
                                            onEnter: (_) =>
                                                hovered.value = true,
                                            onExit: (_) =>
                                                hovered.value = false,
                                            cursor: SystemMouseCursors.click,
                                            child: Tooltip(
                                              message: 'Detayları aç',
                                              child: InkWell(
                                                customBorder:
                                                    const CircleBorder(),
                                                onTap: firstCourse == null
                                                    ? null
                                                    : () {
                                                        CourseDetailOverlay
                                                            .show(
                                                              ctx,
                                                              course:
                                                                  firstCourse,
                                                              accentColor:
                                                                  groupColor,
                                                              heroTag: heroTag,
                                                            );
                                                      },
                                                child: Hero(
                                                  tag: heroTag,
                                                  child: avatar,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      title: Text(
                                        '${group.code} - ${group.name}',
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: selectedCount > 0
                                          ? Text(
                                              '$selectedCount/${group.sections.length} şube seçili',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          : Text(
                                              '${group.sections.length} şube',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                      children: [
                                        // Group-level action: select all sections
                                        Builder(
                                          builder: (context) {
                                            final hasMultipleSections =
                                                group.sections.length > 1;
                                            final hasSectionField = group
                                                .sections
                                                .any((c) => c.section.isNotEmpty);
                                            final allSelected =
                                                selectedCount ==
                                                    group.sections.length &&
                                                group.sections.isNotEmpty;
                                            if (!(hasMultipleSections &&
                                                hasSectionField)) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.fromLTRB(
                                                0,
                                                0,
                                                0,
                                                0,
                                              ),
                                              child: CheckboxListTile(
                                                dense: true,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 0,
                                                    ),
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                value: allSelected,
                                                onChanged: (val) {
                                                  final notifier = ref.read(
                                                    selectedCoursesProvider
                                                        .notifier,
                                                  );
                                                  if (val == true) {
                                                    notifier.selectAllSections(
                                                      group.sections,
                                                    );
                                                  } else {
                                                    notifier.deselectAllSections(
                                                      group.sections,
                                                    );
                                                  }
                                                },
                                                title: const Text(
                                                  'Tüm şubeleri seç',
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                      ...group.sections.map((course) {
                                        final isSelected = selectedCoursesList
                                            .contains(course);
                                        final courseKey =
                                            course.section.isNotEmpty
                                            ? '${course.code}-${course.section}'
                                            : course.code;
                                        final courseColor = ref
                                            .read(courseColorsProvider.notifier)
                                            .getColorForCourse(courseKey);

                                        return MouseRegion(
                                          onEnter: (_) {
                                            hoveredGroup.value = null;
                                            hoveredCourse.value = course;
                                          },
                                          onExit: (_) {
                                            if (hoveredCourse.value == course) {
                                              hoveredCourse.value = null;
                                              hoveredGroup.value = group;
                                            }
                                          },
                                          child: ListTile(
                                            dense: true,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    12,
                                                  ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 0,
                                                ),
                                            leading: Container(
                                              width: 24,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: courseColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            title: Text(
                                              course.section.isNotEmpty
                                                  ? 'Section ${course.section}'
                                                  : group.code,
                                              style: TextStyle(
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : null,
                                                fontSize: 13,
                                              ),
                                            ),
                                            subtitle: Wrap(
                                              spacing: 8,
                                              runSpacing: 2,
                                              children: [
                                                if (course.schedule.isNotEmpty)
                                                  Text(
                                                    course.schedule,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                if (course.room.isNotEmpty)
                                                  Text(
                                                    course.room,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                if (course.lecturer.isNotEmpty)
                                                  Text(
                                                    course.lecturer,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            trailing: Checkbox(
                                              value: isSelected,
                                              onChanged: (value) {
                                                ref
                                                    .read(
                                                      selectedCoursesProvider
                                                          .notifier,
                                                    )
                                                    .toggleCourse(course);
                                              },
                                              activeColor: courseColor,
                                            ),
                                            onTap: () {
                                              ref
                                                  .read(
                                                    selectedCoursesProvider
                                                        .notifier,
                                                  )
                                                  .toggleCourse(course);
                                            },
                                          ),
                                        );
                                      }),
                                      // const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ));
                            },
                          ),
                  ),
                ],
              );

          final schedulePanel = Column(
            children: [
              // Sağ taraf - Program tablosu
                  // Başlık ve kombinasyon navigasyonu
                  Container(
                    padding: EdgeInsets.only(
                      left: isCompact ? 8 : 16,
                      right: isCompact ? 8 : 16,
                      top: 8,
                      bottom: 0,
                    ),
                    child: Column(
                      children: [
                        if (selectedCourses.isNotEmpty &&
                            combinations.isEmpty) ...[
                          // const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Seçtiğiniz derslere uygun program oluşturulamadı. Filtreleri veya ders seçimini düzenleyin.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Aktif kombinasyondaki dersler
                        if (combinations.isNotEmpty &&
                            activeIndex < combinations.length) ...[
                          // const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Builder(
                              builder: (context) {
                                final chips = Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: combinations[activeIndex].map((
                                    course,
                                  ) {
                                    final courseKey = course.section.isNotEmpty
                                        ? '${course.code}-${course.section}'
                                        : course.code;
                                    final courseColor = ref
                                        .read(courseColorsProvider.notifier)
                                        .getColorForCourse(courseKey);

                                    return Material(
                                      type: MaterialType.transparency,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: courseColor.withValues(
                                            alpha: 0.8,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              course.section.isNotEmpty
                                                  ? course.section
                                                  : course.code,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () {
                                                ref
                                                    .read(
                                                      selectedCoursesProvider
                                                          .notifier,
                                                    )
                                                    .removeCourse(course);
                                              },
                                              child: const Icon(
                                                Icons.close,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                                final navigation = combinations.length > 1
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: activeIndex > 0
                                                  ? () {
                                                      ref
                                                          .read(
                                                            activeCombinationIndexProvider
                                                                .notifier,
                                                          )
                                                          .previousCombination();
                                                    }
                                                  : null,
                                              icon: const Icon(
                                                Icons.chevron_left,
                                              ),
                                              iconSize: 20,
                                              constraints: const BoxConstraints(
                                                minWidth: 20,
                                                minHeight: 20,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: Text(
                                                '${activeIndex + 1}/${combinations.length}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed:
                                                  activeIndex <
                                                      combinations.length - 1
                                                  ? () {
                                                      ref
                                                          .read(
                                                            activeCombinationIndexProvider
                                                                .notifier,
                                                          )
                                                          .nextCombination();
                                                    }
                                                  : null,
                                              icon: const Icon(
                                                Icons.chevron_right,
                                              ),
                                              iconSize: 20,
                                              constraints: const BoxConstraints(
                                                minWidth: 20,
                                                minHeight: 20,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink();

                                if (isCompact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      chips,
                                      if (combinations.length > 1) ...[
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: navigation,
                                        ),
                                      ],
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: chips),
                                    const SizedBox(width: 8),
                                    navigation,
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Program tablosu
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isCompact ? 8 : 16,
                        8,
                        isCompact ? 8 : 16,
                        8,
                      ),
                      child: ScheduleTable(
                        scheduleTable: scheduleTable,
                        previewCourses: hoveredPreviewCourses,
                      ),
                    ),
                  ),
                ],
              );

          if (isCompact) {
            return TabBarView(
              children: [
                courseListPanel,
                schedulePanel,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 1, child: courseListPanel),
              Container(width: 1, color: Theme.of(context).dividerColor),
              Expanded(flex: 2, child: schedulePanel),
            ],
          );
        },
      ),
    );

    if (!isCompact) {
      return scaffold;
    }
    return DefaultTabController(length: 2, child: scaffold);
  }
}

Future<void> _saveCurrentSchedule(BuildContext context, WidgetRef ref) async {
  final combinations = ref.read(scheduleCombinationsProvider);
  if (combinations.isEmpty) {
    AppSnackBar.showWarning(context, 'Kaydedilecek program yok.');
    return;
  }

  final idx = ref.read(activeCombinationIndexProvider);
  final active = (idx < combinations.length)
      ? combinations[idx]
      : combinations.first;

  final editingId = ref.read(editingScheduleIdProvider);
  final nameController = TextEditingController(
    text: editingId == null
        ? 'Program ${DateTime.now().toLocal().toString().substring(0, 16)}'
        : null,
  );

  final action = await showDialog<_SaveAction>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Programı Kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (editingId == null)
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ad'),
              )
            else
              const Text(
                'Mevcut programı güncellemek mi istersiniz, yoksa yeni olarak kaydetmek mi?',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          if (editingId != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, _SaveAction.update),
              child: const Text('Güncelle'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _SaveAction.create),
            child: const Text('Kaydet'),
          ),
        ],
      );
    },
  );

  if (!context.mounted) return;
  if (action == null) return;

  final notifier = ref.read(savedSchedulesProvider.notifier);

  // Dataset bilgisini al
  final currentDataset = ref.read(currentDatasetInfoProvider);
  // Geçerli filtre ayarlarını al
  final allowConflicts = ref.read(allowConflictsProvider);
  final minFreeDays = ref.read(minFreeDaysProvider);

  if (action == _SaveAction.update && editingId != null) {
    await notifier.update(
      editingId,
      courses: active,
      allowConflicts: allowConflicts,
      minFreeDays: minFreeDays,
    );
    if (!context.mounted) return;
    AppSnackBar.showSuccess(context, 'Program güncellendi.');
  } else {
    final name = (nameController.text.trim().isEmpty)
        ? 'Program ${DateTime.now().millisecondsSinceEpoch}'
        : nameController.text.trim();

    final savedSchedules = ref.read(savedSchedulesProvider);
    SavedSchedule? existingSchedule;
    for (final schedule in savedSchedules) {
      if (schedule.name.trim().toLowerCase() == name.toLowerCase() &&
          schedule.id != editingId) {
        existingSchedule = schedule;
        break;
      }
    }

    if (existingSchedule != null) {
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Program mevcut'),
          content: Text(
            '"$name" isminde kayıtlı bir program zaten var. Üzerine yazmak ister misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Üzerine Yaz'),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      if (overwrite != true) {
        return;
      }

      await notifier.update(
        existingSchedule.id,
        courses: active,
        allowConflicts: allowConflicts,
        minFreeDays: minFreeDays,
        datasetPath: currentDataset?.path,
      );
      if (!context.mounted) return;
      AppSnackBar.showSuccess(context, 'Program üzerine yazıldı.');
      return;
    }
    await notifier.saveNew(
      name,
      active,
      datasetYear: currentDataset?.year,
      datasetPeriod: currentDataset?.period,
      datasetPath: currentDataset?.path,
      allowConflicts: allowConflicts,
      minFreeDays: minFreeDays,
    );
    ref.read(editingScheduleIdProvider.notifier).set(null);
    if (!context.mounted) return;
    AppSnackBar.showSuccess(context, 'Program kaydedildi.');
  }
}

Future<void> _showExportDialog(
  BuildContext context,
  List<Course> selectedCourses,
) async {
  // Derle: seçilen derslerin Section kodları (ör. CMPE 421_01)
  final sections = buildExportLines(selectedCourses);
  final exportText = buildExportText(selectedCourses);

  final controller = TextEditingController(text: exportText);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Seçilen Dersler'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aşağıdaki alan kopyalanabilir. Toplam ${sections.length} satır.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              readOnly: true,
              maxLines: 8,
              minLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Kapat'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: exportText));
            if (!ctx.mounted) return;
            AppSnackBar.showSuccess(ctx, 'Panoya kopyalandı');
          },
          icon: const Icon(Icons.copy),
          label: const Text('Kopyala'),
        ),
      ],
    ),
  );
}

/// Renkleri karıştırarak yeni bir renk hesaplar
Color _calculateMixedColor(List<Color> colors) {
  if (colors.isEmpty) return Colors.grey;
  if (colors.length == 1) return colors.first;

  int totalRed = 0, totalGreen = 0, totalBlue = 0;

  for (final color in colors) {
    totalRed += (color.r * 255.0).round() & 0xff;
    totalGreen += (color.g * 255.0).round() & 0xff;
    totalBlue += (color.b * 255.0).round() & 0xff;
  }

  return Color.fromARGB(
    255,
    (totalRed / colors.length).round(),
    (totalGreen / colors.length).round(),
    (totalBlue / colors.length).round(),
  );
}

enum _SaveAction { create, update }

enum _CourseSelectionMenuAction { export, save, clear, datasets }

class _PreviewEntry {
  final Color color;
  final String label;

  const _PreviewEntry({
    required this.color,
    required this.label,
  });
}

String _previewLabelForCourse(Course course) {
  if (course.section.isNotEmpty) {
    return course.section;
  }
  return course.code;
}

String _scheduleTableLabelForCourse(Course course) {
  final lines = <String>[
    course.section.isNotEmpty ? course.section : course.code,
    if (course.lecturer.isNotEmpty) course.lecturer,
    if (course.room.isNotEmpty) course.room,
  ];
  return lines.join('\n');
}

class ScheduleTable extends ConsumerWidget {
  final Map<String, Map<String, List<Course>>> scheduleTable;
  final List<Course> previewCourses;

  const ScheduleTable({
    super.key,
    required this.scheduleTable,
    this.previewCourses = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeSlots = ScheduleTableConstants.timeSlots;
    final days = ScheduleTableConstants.days;
    final conflictColor = Theme.of(context).colorScheme.error;
    final isCompact = MediaQuery.of(context).size.width < 900;
    final timeColumnWidth = isCompact ? 56.0 : 80.0;
    final dayColumnWidth = isCompact ? 120.0 : 150.0;
    final headerHeight = isCompact ? 28.0 : 32.0;
    final rowHeight = isCompact ? 42.0 : 48.0;
    final presentCourseIds = <String>{};
    for (final dayMap in scheduleTable.values) {
      for (final coursesAtTime in dayMap.values) {
        for (final course in coursesAtTime) {
          presentCourseIds.add(course.id);
        }
      }
    }

    final previewEntriesByCell = <String, List<_PreviewEntry>>{};
    for (final course in previewCourses) {
      if (course.schedule.isEmpty) continue;
      if (presentCourseIds.contains(course.id)) continue;
      final courseKey = course.section.isNotEmpty
          ? '${course.code}-${course.section}'
          : course.code;
      final color = ref
          .read(courseColorsProvider.notifier)
          .getColorForCourse(courseKey);
      final label = _previewLabelForCourse(course);
      final slots = parseMultipleTimeSlots(course.schedule);
      for (final slot in slots) {
        if (slot.day.isEmpty || slot.startHour <= 0) continue;
        for (int hour = slot.startHour; hour < slot.endHour; hour++) {
          final hourString = '${hour.toString().padLeft(2, '0')}:00';
          final key = '${slot.day}|$hourString';
          final entries = previewEntriesByCell.putIfAbsent(
            key,
            () => <_PreviewEntry>[],
          );
          entries.add(
            _PreviewEntry(color: color, label: label),
          );
        }
      }
    }

    final table = Table(
      border: TableBorder.all(color: Theme.of(context).dividerColor, width: 1),
      columnWidths: {
        0: FixedColumnWidth(timeColumnWidth),
        for (int i = 1; i <= days.length; i++)
          i: FixedColumnWidth(dayColumnWidth),
      },
      children: [
        // Başlık satırı
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          ),
          children: [
            TableCell(
              child: Container(
                height: headerHeight,
                alignment: Alignment.center,
                child: Text(
                  'Saat',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ...days.map(
              (day) => TableCell(
                child: Container(
                  height: headerHeight,
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Zaman satırları
        ...timeSlots.map(
          (timeSlot) => TableRow(
            children: [
              // Saat kolonu
              TableCell(
                child: Container(
                  height: rowHeight,
                  alignment: Alignment.center,
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  child: Text(
                    ScheduleTableConstants.formatTimeSlotForDisplay(timeSlot),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Günlerin kolonları
              ...days.map((day) {
                final coursesAtTime = scheduleTable[day]?[timeSlot] ?? [];
                final previewEntries =
                    previewEntriesByCell['$day|$timeSlot'] ?? const [];
                final hasConflict =
                    coursesAtTime.isNotEmpty && previewEntries.isNotEmpty;

                return TableCell(
                  verticalAlignment: TableCellVerticalAlignment.fill,
                  child: Container(
                    height: rowHeight,
                    padding: const EdgeInsets.all(2),
                    child: Stack(
                      children: [
                        if (coursesAtTime.isNotEmpty)
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: coursesAtTime.map((course) {
                              final courseKey = course.section.isNotEmpty
                                  ? '${course.code}-${course.section}'
                                  : course.code;
                              final courseColor = ref
                                  .read(courseColorsProvider.notifier)
                                  .getColorForCourse(courseKey);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 1,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      final courseKey =
                                          course.section.isNotEmpty
                                          ? '${course.code}-${course.section}'
                                          : course.code;
                                      final accent = ref
                                          .read(courseColorsProvider.notifier)
                                          .getColorForCourse(courseKey);
                                      final heroTag =
                                          'course-${course.id}-$day-$timeSlot';
                                      CourseDetailOverlay.show(
                                        context,
                                        course: course,
                                        accentColor: accent,
                                        heroTag: heroTag,
                                      );
                                    },
                                    child: Hero(
                                      tag: 'course-${course.id}-$day-$timeSlot',
                                      createRectTween: (begin, end) =>
                                          MaterialRectCenterArcTween(
                                            begin: begin!,
                                            end: end!,
                                          ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: double.infinity,
                                          height: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: courseColor.withValues(
                                              alpha: 0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: hasConflict
                                                ? Border.all(
                                                    color: conflictColor
                                                        .withValues(
                                                          alpha: 0.9,
                                                        ),
                                                    width: 1.5,
                                                  )
                                                : null,
                                          ),
                                          child: Text(
                                            _scheduleTableLabelForCourse(
                                              course,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        if (previewEntries.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: previewEntries.map((entry) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 1,
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        width: double.infinity,
                                        height: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: entry.color.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: entry.color.withValues(
                                              alpha: 0.45,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          entry.label,
                                          style: TextStyle(
                                            color: entry.color.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        if (hasConflict)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      conflictColor.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: conflictColor.withValues(
                                      alpha: 0.95,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: conflictColor.withValues(
                                        alpha: 0.95,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Çakışma',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );

    final minWidth = timeColumnWidth + (dayColumnWidth * days.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) {
          return table;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: table,
          ),
        );
      },
    );
  }
}
