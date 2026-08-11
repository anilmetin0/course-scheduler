import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/models/time_slot.dart';
import 'package:flutter/services.dart';
import 'package:scheduler/core/services/course_service.dart';
import 'package:scheduler/core/services/analytics_service.dart';
import 'package:scheduler/core/services/analytics_data_service.dart';
import 'package:scheduler/core/services/metrics_service.dart';
import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/features/schedule/providers/saved_schedules_provider.dart';

part 'course_providers.g.dart';

const _kKeyActiveCombinationIndex = 'active_combination_index';

// Course Service Provider
@Riverpod(keepAlive: true)
CourseService courseService(Ref ref) {
  return CourseService();
}

// All Courses Provider
@Riverpod(keepAlive: true)
Future<List<Course>> courses(Ref ref) async {
  final service = ref.read(courseServiceProvider);
  // Clear cache when provider is invalidated
  service.clearCache();

  final assets = await ref.watch(assetDatasetsProvider.future);
  String activePath = ref.watch(activeAssetDatasetPathProvider);
  if (assets.isNotEmpty && !assets.any((m) => m.path == activePath)) {
    activePath = assets.first.path;
  }
  try {
    final text = await rootBundle.loadString(activePath);
    return service.loadCoursesFromString(text, cacheKey: 'asset:$activePath');
  } catch (_) {
    return service.loadCourses(cacheKey: 'assets');
  }
}

// Selected Courses Provider
@Riverpod(keepAlive: true)
class SelectedCourses extends _$SelectedCourses {
  @override
  List<Course> build() {
    // Uygulama başlarken aktif programı yükle
    _loadActiveSchedule();
    return [];
  }

  Future<void> _loadActiveSchedule() async {
    // activeScheduleCoursesProvider'dan dersleri yükle
    // Bu provider zaten ayarları da (allowConflicts, minFreeDays) yüklüyor
    try {
      final activeCourses = ref.read(activeScheduleCoursesProvider);
      if (activeCourses.isNotEmpty) {
        state = activeCourses;
        _queueSelectionSnapshot();
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _saveActiveSchedule() async {
    try {
      final activeScheduleNotifier = ref.read(
        activeScheduleCoursesProvider.notifier,
      );
      await activeScheduleNotifier.saveActiveCourses(state);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  void addCourse(Course course) {
    if (!state.contains(course)) {
      state = [...state, course];
      _saveActiveSchedule();
      _logCourseAdded(course);
      _queueSelectionSnapshot();
    }
  }

  void removeCourse(Course course) {
    state = state.where((c) => c != course).toList();
    _saveActiveSchedule();
    _logCourseRemoved(course);
    _queueSelectionSnapshot();
  }

  void toggleCourse(Course course) {
    if (state.contains(course)) {
      removeCourse(course);
    } else {
      addCourse(course);
    }
  }

  void clearAll() {
    final removed = state;
    state = [];
    _saveActiveSchedule();
    _logCoursesRemoved(removed);
    unawaited(
      AnalyticsService().logEvent('courses_cleared', {
        'course_count': removed.length,
      }),
    );
    unawaited(AnalyticsDataService().logCoursesCleared(removed.length));
    _queueSelectionSnapshot();
  }

  bool isSelected(Course course) {
    return state.contains(course);
  }

  // Batch operations for selecting multiple sections at once
  void addCourses(Iterable<Course> courses) {
    if (courses.isEmpty) return;
    final current = state.toSet();
    final added = courses.where((c) => !current.contains(c)).toList();
    current.addAll(courses);
    state = current.toList();
    _saveActiveSchedule();
    _logCoursesAdded(added);
    _queueSelectionSnapshot();
  }

  void removeCourses(Iterable<Course> courses) {
    if (courses.isEmpty) return;
    final removed = state.where((c) => courses.contains(c)).toList();
    final toRemove = courses.toSet();
    state = state.where((c) => !toRemove.contains(c)).toList();
    _saveActiveSchedule();
    _logCoursesRemoved(removed);
    _queueSelectionSnapshot();
  }

  bool areAllSelected(Iterable<Course> courses) {
    for (final c in courses) {
      if (!state.contains(c)) return false;
    }
    return courses.isNotEmpty;
  }

  void selectAllSections(List<Course> sections) {
    addCourses(sections);
  }

  void deselectAllSections(List<Course> sections) {
    removeCourses(sections);
  }

  void toggleAllSections(List<Course> sections) {
    if (areAllSelected(sections)) {
      removeCourses(sections);
    } else {
      addCourses(sections);
    }
  }

  void _logCourseAdded(Course course) {
    final section = course.section.isNotEmpty ? course.section : null;
    unawaited(
      AnalyticsService().logCourseAdded(
        courseCode: course.code,
        courseName: course.name.isNotEmpty ? course.name : null,
        courseSection: section,
      ),
    );
    unawaited(
      AnalyticsDataService().logCourseSelectionChanged(
        course,
        isAdded: true,
        source: 'single',
      ),
    );
    unawaited(MetricsService().logCourseAdded(course));
  }

  void _logCourseRemoved(Course course) {
    final section = course.section.isNotEmpty ? course.section : null;
    unawaited(
      AnalyticsService().logCourseRemoved(
        courseCode: course.code,
        courseName: course.name.isNotEmpty ? course.name : null,
        courseSection: section,
      ),
    );
    unawaited(
      AnalyticsDataService().logCourseSelectionChanged(
        course,
        isAdded: false,
        source: 'single',
      ),
    );
    unawaited(MetricsService().logCourseRemoved(course));
  }

  void _logCoursesAdded(Iterable<Course> courses) {
    if (courses.isEmpty) return;
    for (final course in courses) {
      final section = course.section.isNotEmpty ? course.section : null;
      unawaited(
        AnalyticsService().logCourseAdded(
          courseCode: course.code,
          courseName: course.name.isNotEmpty ? course.name : null,
          courseSection: section,
        ),
      );
      unawaited(
        AnalyticsDataService().logCourseSelectionChanged(
          course,
          isAdded: true,
          source: 'bulk',
        ),
      );
    }
    unawaited(MetricsService().logCoursesAdded(courses));
  }

  void _logCoursesRemoved(Iterable<Course> courses) {
    if (courses.isEmpty) return;
    for (final course in courses) {
      final section = course.section.isNotEmpty ? course.section : null;
      unawaited(
        AnalyticsService().logCourseRemoved(
          courseCode: course.code,
          courseName: course.name.isNotEmpty ? course.name : null,
          courseSection: section,
        ),
      );
      unawaited(
        AnalyticsDataService().logCourseSelectionChanged(
          course,
          isAdded: false,
          source: 'bulk',
        ),
      );
    }
    unawaited(MetricsService().logCoursesRemoved(courses));
  }

  void _queueSelectionSnapshot() {
    final dataset = ref.read(currentDatasetInfoProvider);
    final allowConflicts = ref.read(allowConflictsProvider);
    final minFreeDays = ref.read(minFreeDaysProvider);
    unawaited(
      AnalyticsDataService().queueSelectionSnapshot(
        state,
        datasetPath: dataset?.path,
        datasetYear: dataset?.year,
        datasetPeriod: dataset?.period,
        allowConflicts: allowConflicts,
        minFreeDays: minFreeDays,
      ),
    );
  }
}

// Course Colors Provider
@Riverpod(keepAlive: true)
class CourseColors extends _$CourseColors {
  @override
  Map<String, Color> build() {
    return {};
  }

  static const List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
    Colors.lightGreen,
    Colors.brown,
    Colors.blueGrey,
    Colors.deepPurple,
  ];

  Color getColorForCourse(String courseCode) {
    if (state.containsKey(courseCode)) {
      return state[courseCode]!;
    }

    // Deterministik renk seçimi - state'i değiştirmeden
    final colorIndex = courseCode.hashCode % _colors.length;
    return _colors[colorIndex.abs()];
  }

  void setColorForCourse(String courseCode, Color color) {
    state = {...state, courseCode: color};
  }
}

// Search Query Provider
@Riverpod(keepAlive: true)
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String query) {
    state = query;
  }
}

// Conflict handling and free days filters
@Riverpod(keepAlive: true)
class AllowConflicts extends _$AllowConflicts {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void set(bool value) {
    state = value;
  }
}

@Riverpod(keepAlive: true)
class MinFreeDays extends _$MinFreeDays {
  @override
  int? build() => null;

  void set(int? days) {
    state = days;
  }

  void clear() {
    state = null;
  }
}

// Filtered Courses Provider
@Riverpod(keepAlive: true)
List<Course> filteredCourses(Ref ref) {
  final coursesAsync = ref.watch(coursesProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return coursesAsync.when(
    data: (courses) {
      if (searchQuery.isEmpty) return courses;

      final lowercaseQuery = searchQuery.toLowerCase();
      return courses
          .where(
            (course) =>
                course.code.toLowerCase().contains(lowercaseQuery) ||
                course.name.toLowerCase().contains(lowercaseQuery) ||
                course.lecturer.toLowerCase().contains(lowercaseQuery),
          )
          .toList();
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
}

// Grouped Courses Provider (groups by course code)
class CourseGroup {
  final String code;
  final String name; // representative name (from first section)
  final List<Course> sections;

  const CourseGroup({
    required this.code,
    required this.name,
    required this.sections,
  });
}

final courseGroupsProvider = Provider<List<CourseGroup>>((ref) {
  final courses = ref.watch(coursesByDepartmentProvider);

  if (courses.isEmpty) return const [];

  final Map<String, List<Course>> grouped = <String, List<Course>>{};
  for (final c in courses) {
    (grouped[c.code] ??= <Course>[]).add(c);
  }

  // Sort groups by code, and sections by section (then lecturer as fallback)
  final sortedCodes = grouped.keys.toList()..sort();
  final List<CourseGroup> groups = [];
  for (final code in sortedCodes) {
    final sections = grouped[code]!
      ..sort((a, b) {
        if (a.section.isEmpty && b.section.isEmpty) return 0;
        if (a.section.isEmpty) return -1;
        if (b.section.isEmpty) return 1;
        final sec = a.section.compareTo(b.section);
        return sec != 0 ? sec : a.lecturer.compareTo(b.lecturer);
      });
    final name = sections.first.name;
    groups.add(CourseGroup(code: code, name: name, sections: sections));
  }

  return groups;
});

// Department Filter Provider
@Riverpod(keepAlive: true)
class SelectedDepartment extends _$SelectedDepartment {
  @override
  String? build() => null;

  void set(String? department) {
    state = department;
  }

  void clear() {
    state = null;
  }
}

// Courses by Department Provider
@Riverpod(keepAlive: true)
List<Course> coursesByDepartment(Ref ref) {
  final courses = ref.watch(filteredCoursesProvider);
  final selectedDepartment = ref.watch(selectedDepartmentProvider);

  if (selectedDepartment == null) return courses;

  return courses
      .where((course) => course.department == selectedDepartment)
      .toList();
}

// Departments Provider
final departmentsProvider = Provider<List<String>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);

  return coursesAsync.when(
    data: (courses) {
      final departments = courses
          .map((course) => course.department)
          .where((dept) => dept.isNotEmpty)
          .toSet()
          .toList();

      departments.sort();
      return departments;
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

// Schedule Combinations Provider - Seçilen derslerden kombinasyonları üretir
final scheduleCombinationsProvider = Provider<List<List<Course>>>((ref) {
  final selectedCourses = ref.watch(selectedCoursesProvider);
  final allowConflicts = ref.watch(allowConflictsProvider);
  final minFreeDays = ref.watch(minFreeDaysProvider);

  if (selectedCourses.isEmpty) return [];

  // Dersları ders koduna göre grupla
  final Map<String, List<Course>> courseGroups = {};
  for (final course in selectedCourses) {
    final courseCode = course.code;
    if (!courseGroups.containsKey(courseCode)) {
      courseGroups[courseCode] = [];
    }
    courseGroups[courseCode]!.add(course);
  }

  // Tüm kombinasyonları hesapla
  List<List<Course>> allCombinations = [[]];

  for (final courseGroup in courseGroups.values) {
    final newCombinations = <List<Course>>[];

    for (final existingCombination in allCombinations) {
      for (final course in courseGroup) {
        final newCombination = [...existingCombination, course];

        // Tüm kombinasyonları üret
        newCombinations.add(newCombination);
      }
    }

    allCombinations = newCombinations;
  }

  // Çakışma filtresi
  List<List<Course>> filtered = allCombinations;
  if (!allowConflicts) {
    filtered = filtered
        .where((combo) => !_combinationHasConflict(combo))
        .toList();
  }

  // Boş gün filtresi (1..4 gün)
  if (minFreeDays != null) {
    filtered = filtered
        .where((combo) => _countFreeWeekdays(combo) >= minFreeDays)
        .toList();
  }

  return filtered;
});

// Active Combination Index Provider
@Riverpod(keepAlive: true)
class ActiveCombinationIndex extends _$ActiveCombinationIndex {
  bool _isInitializing = false;

  @override
  int build() {
    // Storage'dan yükle
    _loadFromStorage();

    // Listen to combination changes and reset index when combinations change
    ref.listen(scheduleCombinationsProvider, (previous, next) {
      // If combinations changed and current index is out of bounds, reset to 0
      if (previous != null && previous != next) {
        if (state >= next.length && next.isNotEmpty) {
          _setAndSave(0);
        } else if (next.isEmpty) {
          _setAndSave(0);
        }
      }
    });
    return 0;
  }

  Future<void> _loadFromStorage() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final savedIndex = await storageService.getString(
        _kKeyActiveCombinationIndex,
      );
      if (savedIndex != null && savedIndex.isNotEmpty) {
        final index = int.tryParse(savedIndex);
        if (index != null && index >= 0) {
          // Kombinasyonlar yüklendikten sonra kontrol et
          final combinations = ref.read(scheduleCombinationsProvider);
          if (combinations.isNotEmpty && index < combinations.length) {
            state = index;
          } else if (combinations.isEmpty) {
            // Kombinasyonlar henüz yüklenmemiş, index'i kaydet
            // ve kombinasyonlar yüklendiğinde kontrol edilecek
            state = index;
          }
        }
      }
    } finally {
      _isInitializing = false;
    }
  }

  void _setAndSave(int index) {
    state = index;
    storageService.setString(_kKeyActiveCombinationIndex, index.toString());
  }

  void setIndex(int index) {
    final combinations = ref.read(scheduleCombinationsProvider);
    if (index >= 0 && index < combinations.length) {
      _setAndSave(index);
    }
  }

  void nextCombination() {
    final combinations = ref.read(scheduleCombinationsProvider);
    if (combinations.length > 1 && state < combinations.length - 1) {
      _setAndSave(state + 1);
    }
  }

  void previousCombination() {
    if (state > 0) {
      _setAndSave(state - 1);
    }
  }
}

// Active Schedule Provider - Aktif kombinasyona göre program
@riverpod
Map<String, Map<String, List<Course>>> activeSchedule(Ref ref) {
  final combinations = ref.watch(scheduleCombinationsProvider);
  final activeIndex = ref.watch(activeCombinationIndexProvider);

  if (combinations.isEmpty) {
    return <String, Map<String, List<Course>>>{};
  }

  final idx = activeIndex < combinations.length ? activeIndex : 0;
  final activeCombination = combinations[idx];

  final schedule = <String, Map<String, List<Course>>>{};
  final days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  final timeSlots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  // Initialize schedule
  for (final day in days) {
    schedule[day] = {};
    for (final timeSlot in timeSlots) {
      schedule[day]![timeSlot] = [];
    }
  }

  // Fill schedule with active combination
  for (final course in activeCombination) {
    final timeSlots = _parseMultipleTimeSlots(course.schedule);

    for (final timeSlot in timeSlots) {
      if (timeSlot.day.isNotEmpty && timeSlot.startHour > 0) {
        for (int hour = timeSlot.startHour; hour < timeSlot.endHour; hour++) {
          final hourString = '${hour.toString().padLeft(2, '0')}:00';
          if (schedule[timeSlot.day]?[hourString] != null) {
            schedule[timeSlot.day]![hourString]!.add(course);
          }
        }
      }
    }
  }

  return schedule;
}

// Birden fazla zaman dilimini parse et
// Örnekler:
//  - "Tu 13 - 15 We 16 - 18 Fr 15 - 16"
//  - "Tu/Fr 13 - 15 Tu/Fr 09 - 12"  (çoklu gün grubu)
List<TimeSlot> _parseMultipleTimeSlots(String schedule) {
  if (schedule.isEmpty) return [];

  final timeSlots = <TimeSlot>[];

  try {
    // 1) Çoklu gün grupları desteği (ör. "Tu/Fr 13 - 15")
    //    Grup bir veya daha fazla 1-3 harfli gün kısaltmalarından oluşabilir ve '/' veya ',' ile ayrılabilir.
    final pattern = RegExp(
      r'([A-Za-zÇĞİÖŞÜçğıöşü]{1,3}(?:[\/,][A-Za-zÇĞİÖŞÜçğıöşü]{1,3})*)\s+(\d{1,2})\s*-\s*(\d{1,2})',
    );
    final matches = pattern.allMatches(schedule);

    for (final match in matches) {
      final dayGroup = match.group(1)!; // örn: "Tu/Fr"
      final startHourStr = match.group(2)!;
      final endHourStr = match.group(3)!;

      final startHour = int.tryParse(startHourStr);
      final endHour = int.tryParse(endHourStr);
      if (startHour == null || endHour == null) continue;

      // Gruptaki her günü ayır ve normalize et
      final rawDays = dayGroup.split(RegExp(r'[\/,]'));
      for (final d in rawDays) {
        final normalizedDay = _normalizeDayName(d.trim());
        if (normalizedDay.isEmpty) continue;
        timeSlots.add(
          TimeSlot(day: normalizedDay, startHour: startHour, endHour: endHour),
        );
      }
    }

    // Eğer regex ile hiçbir şey bulunamadıysa eski yöntemi dene
    if (timeSlots.isEmpty) {
      final timeSlot = TimeSlot.fromSchedule(schedule);
      if (timeSlot.day.isNotEmpty && timeSlot.startHour > 0) {
        timeSlots.add(timeSlot);
      }
    }
  } catch (e) {
    // Hata durumunda eski yöntemi dene
    final timeSlot = TimeSlot.fromSchedule(schedule);
    if (timeSlot.day.isNotEmpty && timeSlot.startHour > 0) {
      timeSlots.add(timeSlot);
    }
  }

  return timeSlots;
}

List<TimeSlot> parseMultipleTimeSlots(String schedule) {
  return _parseMultipleTimeSlots(schedule);
}

// Gün adını normalize et
String _normalizeDayName(String day) {
  final dayMap = {
    // Turkish full names
    'pazartesi': 'Pazartesi',
    'salı': 'Salı',
    'çarşamba': 'Çarşamba',
    'perşembe': 'Perşembe',
    'cuma': 'Cuma',
    'cumartesi': 'Cumartesi',
    'pazar': 'Pazar',
    // English full names
    'monday': 'Pazartesi',
    'tuesday': 'Salı',
    'wednesday': 'Çarşamba',
    'thursday': 'Perşembe',
    'friday': 'Cuma',
    'saturday': 'Cumartesi',
    'sunday': 'Pazar',
    // English abbreviations
    'mo': 'Pazartesi',
    'tu': 'Salı',
    'we': 'Çarşamba',
    'th': 'Perşembe',
    'fr': 'Cuma',
    'sa': 'Cumartesi',
    'su': 'Pazar',
    // Common alternative abbreviations
    'mon': 'Pazartesi',
    'tue': 'Salı',
    'wed': 'Çarşamba',
    'thu': 'Perşembe',
    'fri': 'Cuma',
    'sat': 'Cumartesi',
    'sun': 'Pazar',
  };

  return dayMap[day.toLowerCase()] ?? day;
}

// Yardımcı: Kombinasyonda çakışma var mı?
bool _combinationHasConflict(List<Course> courses) {
  final occupied = <String, Set<int>>{}; // day -> set of occupied hours
  for (final course in courses) {
    final slots = _parseMultipleTimeSlots(course.schedule);
    for (final slot in slots) {
      if (slot.day.isEmpty || slot.startHour <= 0) continue;
      final set = occupied.putIfAbsent(slot.day, () => <int>{});
      for (int h = slot.startHour; h < slot.endHour; h++) {
        if (set.contains(h)) return true; // conflict
        set.add(h);
      }
    }
  }
  return false;
}

// Yardımcı: Haftaiçi (Pzt-Cuma) boş gün sayısını hesapla
int _countFreeWeekdays(List<Course> courses) {
  const weekdays = {'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'};
  final used = <String>{};

  for (final course in courses) {
    final slots = _parseMultipleTimeSlots(course.schedule);
    for (final slot in slots) {
      if (weekdays.contains(slot.day)) used.add(slot.day);
    }
  }

  final freeCount = weekdays.length - used.length;

  return freeCount;
}
