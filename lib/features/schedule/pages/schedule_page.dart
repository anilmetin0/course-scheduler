// Schedule page
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/shared/widgets/app_overflow_menu.dart';
import 'package:scheduler/features/course_selection/providers/course_providers.dart';
import 'package:scheduler/features/course_selection/pages/course_selection_page.dart';
import 'package:scheduler/features/datasets/pages/datasets_page.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/config/constants.dart';
import 'package:scheduler/features/schedule/providers/saved_schedules_provider.dart';
import 'package:scheduler/shared/widgets/course_detail_overlay.dart';
import 'package:scheduler/shared/widgets/app_snackbar.dart';
import 'package:scheduler/core/services/analytics_service.dart';
import 'package:scheduler/core/services/analytics_data_service.dart';
import 'package:scheduler/core/utils/export_format.dart';
import 'package:flutter/services.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCourses = ref.watch(selectedCoursesProvider);
    final scheduleTable = ref.watch(activeScheduleProvider);
    final savedSchedules = ref.watch(savedSchedulesProvider);
    final combinations = ref.watch(scheduleCombinationsProvider);

    // Analytics: Sayfa görüntüleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService().logScreenView('schedule_page');
      AnalyticsService().logEvent('page_view', {
        'screen_name': 'schedule_page',
        'selected_courses_count': selectedCourses.length,
        'saved_schedules_count': savedSchedules.length,
        'combinations_count': combinations.length,
      });
      AnalyticsDataService().logEvent('page_view', {
        'screen_name': 'schedule_page',
        'selected_courses_count': selectedCourses.length,
        'saved_schedules_count': savedSchedules.length,
        'combinations_count': combinations.length,
      });
    });

    // Aktif kayıttan seçili dersleri asenkron yükleme tamamlandığında senkronize et
    // Dataset ayarlama işlemi artık ActiveAssetDatasetPath ve ActiveScheduleCourses
    // provider'larında otomatik olarak yapılıyor
    ref.listen<List<Course>>(activeScheduleCoursesProvider, (prev, next) async {
      final currentSelected = ref.read(selectedCoursesProvider);

      // Dersler yüklendiyse ve seçili dersler boşsa, dersleri yükle
      if (next.isNotEmpty && currentSelected.isEmpty) {
        final notifier = ref.read(selectedCoursesProvider.notifier);
        for (final c in next) {
          notifier.addCourse(c);
        }
      }
    });

    // Yeni dönem uyarısı kontrolü
    ref.listen<NewerDatasetInfo?>(newerDatasetAvailableProvider, (prev, next) {
      if (next == null) return;

      // Daha önce bu dataset için uyarı kapatıldıysa gösterme
      final dismissed = ref.read(newerDatasetDismissedProvider);
      if (dismissed == next.newerDataset.path) return;

      // Ana ekranda yüklü program varsa uyarı göster
      final activeCourses = ref.read(activeScheduleCoursesProvider);
      if (activeCourses.isEmpty) return;

      // Dialog göster
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNewerDatasetDialog(context, ref, next);
      });
    });

    final isCompact = MediaQuery.of(context).size.width < 900;
    final listPanel = SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (savedSchedules.isNotEmpty) _SavedSchedulesList(),

          if (selectedCourses.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                isCompact ? 12 : 16,
                0,
                isCompact ? 12 : 16,
                isCompact ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final currentDataset = ref.watch(
                        currentDatasetInfoProvider,
                      );
                      String termInfo = '';
                      if (currentDataset?.year != null &&
                          currentDataset?.period != null) {
                        termInfo =
                            ' (${currentDataset!.year} ${currentDataset.period}. dönem)';
                      } else if (currentDataset?.name != null) {
                        termInfo = ' (${currentDataset!.name})';
                      }

                      return Text(
                        'Seçilen Dersler$termInfo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final Map<String, List<Course>> selectedByCode = {};
                      for (final c in selectedCourses) {
                        (selectedByCode[c.code] ??= <Course>[]).add(c);
                      }

                      final notifier = ref.read(
                        selectedCoursesProvider.notifier,
                      );

                      return Column(
                        children: selectedByCode.entries.map((entry) {
                          final code = entry.key;
                          final list = entry.value;
                          final first = list.first;

                          final color = _calculateMixedColor(
                            list
                                .map((course) {
                                  final courseKey = course.section.isNotEmpty
                                      ? '${course.code}-${course.section}'
                                      : course.code;
                                  return ref
                                      .read(courseColorsProvider.notifier)
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () =>
                                            notifier.removeCourses(list),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: .9),
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
                                      final label = course.section.isNotEmpty
                                          ? course.section
                                          : course.code;
                                      final courseKey =
                                          course.section.isNotEmpty
                                              ? '${course.code}-${course.section}'
                                              : course.code;
                                      final chipColor = ref
                                          .read(courseColorsProvider.notifier)
                                          .getColorForCourse(courseKey);
                                      return Hero(
                                        tag: 'course_chip_$courseKey',
                                        child: Material(
                                          type: MaterialType.transparency,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: chipColor.withValues(
                                                alpha: .85,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    label,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: false,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                GestureDetector(
                                                  onTap: () => notifier
                                                      .removeCourse(course),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
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
        ],
      ),
    );

    final schedulePanel = Column(
      children: [
        if (selectedCourses.isNotEmpty && combinations.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seçtiğiniz derslere uygun program oluşturulamadı. Filtreleri veya ders seçimini düzenleyin.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: selectedCourses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz ders seçmediniz',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ders eklemek için aşağıdaki butonu kullanın',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(isCompact ? 8 : 16),
                    child: ScheduleTable(scheduleTable: scheduleTable),
                  ),
                ),
        ),
      ],
    );

    final body = isCompact
        ? TabBarView(children: [schedulePanel, listPanel])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: listPanel),
              Container(width: 1, color: Theme.of(context).dividerColor),
              Expanded(flex: 2, child: schedulePanel),
            ],
          );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: isCompact
            ? const Text('Ders Programı')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo/logo.png', height: 32, width: 32),
                  const SizedBox(width: 8),
                  const Text('Ders Programı'),
                ],
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Dışarı aktar',
            onPressed: combinations.isNotEmpty
                ? () {
                    final idx = ref.read(activeCombinationIndexProvider);
                    final safeIndex = idx < combinations.length ? idx : 0;
                    final exportCourses = combinations[safeIndex];
                    // Analytics: Dışa aktarma başlatma
                    AnalyticsService().logEvent('export_button_clicked', {
                      'course_count': exportCourses.length,
                      'combinations_available': combinations.length,
                    });
                    AnalyticsDataService().logScheduleExported(
                      format: 'text',
                      courses: exportCourses,
                    );
                    _showExportDialog(context, exportCourses);
                  }
                : null,
          ),
          IconButton(
            tooltip: 'Tümünü Temizle',
            icon: const Icon(Icons.clear_all),
            onPressed: selectedCourses.isNotEmpty
                ? () {
                    // Analytics: Tüm dersleri temizleme
                    AnalyticsService().logEvent('clear_all_courses', {
                      'cleared_course_count': selectedCourses.length,
                    });

                    ref.read(selectedCoursesProvider.notifier).clearAll();
                  }
                : null,
          ),
          IconButton(
            tooltip: 'Dersler',
            icon: const Icon(Icons.library_books_outlined),
            onPressed: () {
              // Analytics: Veri setleri sayfasına gitme
              AnalyticsService().logEvent('datasets_page_opened');
              AnalyticsDataService().logEvent(
                'datasets_page_opened',
                const <String, Object?>{},
              );

              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DatasetsPage()),
              );
            },
          ),
          const AppOverflowMenu(),
          const SizedBox(width: 8),
        ],
        bottom: isCompact
            ? const TabBar(
                tabs: [
                  Tab(text: 'Program'),
                  Tab(text: 'Listeler'),
                ],
              )
            : null,
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CourseSelectionPage(),
            ),
          );
        },
        tooltip: 'Ders Ekle',
        child: const Icon(Icons.add),
      ),
    );

    if (!isCompact) {
      return scaffold;
    }
    return DefaultTabController(length: 2, child: scaffold);
  }
}

Future<void> _showExportDialog(
  BuildContext context,
  List<Course> courses,
) async {
  final sections = buildExportLines(courses);
  final exportText = buildExportText(courses);
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

  const ScheduleTable({super.key, required this.scheduleTable});

  // Unified overlay now provided by CourseDetailOverlay.show

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ScheduleTableConstants.days;
    final timeSlots = ScheduleTableConstants.timeSlots;
    final isCompact = MediaQuery.of(context).size.width < 900;
    final timeColumnWidth = isCompact ? 56.0 : 80.0;
    final dayColumnWidth = isCompact ? 120.0 : 150.0;
    final headerHeight = isCompact ? 28.0 : 32.0;
    final rowHeight = isCompact ? 42.0 : 48.0;

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

                return TableCell(
                  verticalAlignment: TableCellVerticalAlignment.fill,
                  child: Container(
                    height: rowHeight,
                    padding: const EdgeInsets.all(2),
                    child: coursesAtTime.isEmpty
                        ? Container()
                        : Column(
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

class _SavedSchedulesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(savedSchedulesProvider);
    final isCompact = MediaQuery.of(context).size.width < 900;

    if (schedules.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 16,
        0,
        isCompact ? 12 : 16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kaydedilen Programlar',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedules.length,
            separatorBuilder: (c, i) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = schedules[index];

              // Dönem bilgisini oluştur
              String termInfo = '';
              if (s.datasetYear != null && s.datasetPeriod != null) {
                termInfo = '${s.datasetYear} ${s.datasetPeriod}. dönem';
              } else if (s.datasetYear != null) {
                termInfo = s.datasetYear!;
              }

              return Card(
                child: ListTile(
                  title: Text(s.name, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s.courses.length} ders'),
                      if (termInfo.isNotEmpty)
                        Text(
                          termInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  leading: const Icon(Icons.event_note_outlined),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Yükle',
                        icon: const Icon(Icons.download_outlined),
                        onPressed: () => _loadSchedule(context, ref, s),
                      ),
                      IconButton(
                        tooltip: 'Düzenle',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editSchedule(context, ref, s),
                      ),
                      IconButton(
                        tooltip: 'Yeniden Adlandır',
                        icon: const Icon(Icons.drive_file_rename_outline),
                        onPressed: () async {
                          final controller = TextEditingController(
                            text: s.name,
                          );
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Programı Yeniden Adlandır'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Ad',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('İptal'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(
                                    ctx,
                                    controller.text.trim(),
                                  ),
                                  child: const Text('Kaydet'),
                                ),
                              ],
                            ),
                          );
                          if (newName != null && newName.isNotEmpty) {
                            await ref
                                .read(savedSchedulesProvider.notifier)
                                .update(s.id, name: newName);
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Sil',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Programı Sil'),
                              content: Text(
                                '"${s.name}" programı silinsin mi?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('İptal'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Sil'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await ref
                                .read(savedSchedulesProvider.notifier)
                                .remove(s.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Dataset uyarısı ve program yükleme fonksiyonları
Future<void> _loadSchedule(
  BuildContext context,
  WidgetRef ref,
  dynamic s,
) async {
  await _checkDatasetAndLoad(context, ref, s, isEdit: false);
}

Future<void> _editSchedule(
  BuildContext context,
  WidgetRef ref,
  dynamic s,
) async {
  final success = await _checkDatasetAndLoad(context, ref, s, isEdit: true);
  if (!context.mounted) return;
  if (success) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CourseSelectionPage()),
    );
  }
}

Future<bool> _checkDatasetAndLoad(
  BuildContext context,
  WidgetRef ref,
  dynamic s, {
  required bool isEdit,
}) async {
  // Dataset listesi hazır olmadan karşılaştırma yapmayalım
  // (İlk yüklemede 'Bilinmeyen dönem' ve gereksiz uyarı oluşuyordu)
  final datasets = await ref.read(assetDatasetsProvider.future);
  if (!context.mounted) return false;

  // Aktif path'i al ve doğrula; boş/Geçersiz ise en günceli ata
  var effectiveCurrentPath = ref.read(activeAssetDatasetPathProvider);
  final hasActiveInList = datasets.any((d) => d.path == effectiveCurrentPath);
  if (effectiveCurrentPath.isEmpty || !hasActiveInList) {
    final mostRecent = datasets.first; // zaten en güncel olacak şekilde sıralı
    ref.read(activeAssetDatasetPathProvider.notifier).set(mostRecent.path);
    effectiveCurrentPath = mostRecent.path;
  }

  // Güncel dataset bilgisini listeden belirle
  final currentDataset = datasets.firstWhere(
    (d) => d.path == effectiveCurrentPath,
  );

  // Kaydedilen programın dataset bilgisi
  final savedDatasetPath = s.datasetPath;
  final savedYear = s.datasetYear;
  final savedPeriod = s.datasetPeriod;

  // Eğer programın dataset'i mevcut dataset'ten farklıysa uyarı göster
  if (savedDatasetPath != null && savedDatasetPath != effectiveCurrentPath) {
    String currentTerm = 'Bilinmeyen dönem';
    String savedTerm = 'Bilinmeyen dönem';

    if (currentDataset.year != null && currentDataset.period != null) {
      currentTerm = '${currentDataset.year} ${currentDataset.period}. dönem';
    } else {
      currentTerm = currentDataset.name;
    }

    if (savedYear != null && savedPeriod != null) {
      savedTerm = '$savedYear $savedPeriod. dönem';
    }

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Veriseti Değiştirilecek'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bu program farklı bir dönemde kaydedilmiş.'),
            const SizedBox(height: 8),
            Text('Mevcut dönem: $currentTerm'),
            Text(
              'Program dönemi: $savedTerm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Programı yüklemek için veriseti değiştirilecek.'),
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
            child: const Text('Değiştir ve Yükle'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return false;

    // Dataset'i değiştir
    ref.read(activeAssetDatasetPathProvider.notifier).set(savedDatasetPath);
  }

  // Programı yükle
  final notifier = ref.read(selectedCoursesProvider.notifier);
  notifier.clearAll();
  for (final c in s.courses) {
    notifier.addCourse(c);
  }

  // Kaydedilen programın filtre ayarlarını uygula
  try {
    ref.read(allowConflictsProvider.notifier).set(s.allowConflicts);
    ref.read(minFreeDaysProvider.notifier).set(s.minFreeDays);
  } catch (_) {
    // ignore provider errors silently
  }

  // Aktif program courses'ını kaydet (dataset bilgisi ile birlikte)
  final activeCoursesNotifier = ref.read(
    activeScheduleCoursesProvider.notifier,
  );
  await activeCoursesNotifier.saveActiveCourses(s.courses, scheduleId: s.id);

  if (isEdit) {
    ref.read(editingScheduleIdProvider.notifier).set(s.id);
  } else {
    ref.read(editingScheduleIdProvider.notifier).set(null);
  }

  return true;
}

/// Yeni dönem verisi mevcut uyarı dialog'u
void _showNewerDatasetDialog(
  BuildContext context,
  WidgetRef ref,
  NewerDatasetInfo info,
) {
  // Dialog zaten açıksa tekrar gösterme
  if (ModalRoute.of(context)?.isCurrent != true) return;

  final currentYear = info.currentDataset.year ?? '';
  final currentPeriod = info.currentDataset.period ?? '';
  final newerYear = info.newerDataset.year ?? '';
  final newerPeriod = info.newerDataset.period ?? '';

  String currentLabel = '';
  if (currentYear.isNotEmpty) {
    currentLabel = currentYear;
    if (currentPeriod.isNotEmpty) {
      currentLabel +=
          ' - ${currentPeriod == '1'
              ? 'Güz'
              : currentPeriod == '2'
              ? 'Bahar'
              : '$currentPeriod. Dönem'}';
    }
  }

  String newerLabel = '';
  if (newerYear.isNotEmpty) {
    newerLabel = newerYear;
    if (newerPeriod.isNotEmpty) {
      newerLabel +=
          ' - ${newerPeriod == '1'
              ? 'Güz'
              : newerPeriod == '2'
              ? 'Bahar'
              : '$newerPeriod. Dönem'}';
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text('Yeni Dönem Verisi'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daha yeni bir dönem verisi mevcut!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (currentLabel.isNotEmpty) Text('Mevcut: $currentLabel'),
          if (newerLabel.isNotEmpty)
            Text(
              'Yeni: $newerLabel',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 16),
          const Text(
            'Yeni döneme geçmek ister misiniz?\n'
            'Not: Yeni döneme geçerseniz mevcut programınız temizlenecektir.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Hayır - bu dataset için uyarıyı kapat
            ref
                .read(newerDatasetDismissedProvider.notifier)
                .dismiss(info.newerDataset.path);
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Hayır, Kalsın'),
        ),
        FilledButton(
          onPressed: () async {
            // Evet - programı temizle ve yeni dataset'e geç
            // Seçili dersleri temizle
            ref.read(selectedCoursesProvider.notifier).clearAll();

            // Aktif programı temizle
            await ref.read(activeScheduleCoursesProvider.notifier).clear();

            // Yeni dataset'e geç
            ref
                .read(activeAssetDatasetPathProvider.notifier)
                .set(info.newerDataset.path);

            // Dismissed state'i sıfırla
            ref.read(newerDatasetDismissedProvider.notifier).reset();

            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();

            // Bilgi mesajı göster
            if (context.mounted) {
              AppSnackBar.showSuccess(
                context,
                'Yeni döneme geçildi: $newerLabel',
              );
            }
          },
          child: const Text('Evet, Geç'),
        ),
      ],
    ),
  );
}

// Local detail item removed; using shared CourseDetailOverlay.
