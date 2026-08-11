import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:scheduler/core/services/storage_service.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/models/saved_schedule.dart';
import 'package:scheduler/core/services/analytics_data_service.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:scheduler/features/course_selection/providers/course_providers.dart';

part 'saved_schedules_provider.g.dart';

const _kKeyItems = 'saved_schedules_items';
const _kKeyActiveSchedule = 'active_schedule_courses';
const _kKeyActiveScheduleId = 'active_schedule_id';

// Editing Schedule ID Provider
@Riverpod(keepAlive: true)
class EditingScheduleId extends _$EditingScheduleId {
  @override
  String? build() => null;

  void set(String? id) {
    state = id;
  }
}

// Active Schedule Courses Provider
@Riverpod(keepAlive: true)
class ActiveScheduleCourses extends _$ActiveScheduleCourses {
  bool _isDisposed = false;
  bool _hasLoaded = false;

  @override
  List<Course> build() {
    _isDisposed = false;
    _hasLoaded = false;
    ref.onDispose(() => _isDisposed = true);
    // Provider ilk oluşturulduğunda load'ı çağır
    if (!_hasLoaded) {
      Future.microtask(() => load());
    }
    return const [];
  }

  Future<void> load() async {
    if (_hasLoaded) return;
    _hasLoaded = true;
    try {
      final raw = await storageService.getString(_kKeyActiveSchedule);
      if (_isDisposed) return;
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List<dynamic>;
        final courses = decoded
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
        state = courses;

        // Aktif programın ID'sini al ve o programın ayarlarını yükle
        final scheduleId = await storageService.getString(
          _kKeyActiveScheduleId,
        );
        if (_isDisposed) return;
        if (scheduleId != null && scheduleId.isNotEmpty) {
          // Kaydedilmiş programları yükle
          final schedulesRaw = await storageService.getString(_kKeyItems);
          if (_isDisposed) return;
          if (schedulesRaw != null && schedulesRaw.isNotEmpty) {
            final schedulesDecoded = json.decode(schedulesRaw) as List<dynamic>;
            final schedules = schedulesDecoded
                .map((e) => SavedSchedule.fromJson(e as Map<String, dynamic>))
                .toList();

            // ID'ye göre programı bul
            final savedSchedule = schedules.cast<SavedSchedule?>().firstWhere(
              (s) => s?.id == scheduleId,
              orElse: () => null,
            );

            // Eğer program bulunduysa ayarlarını geri yükle
            // Dataset path ayarlama işlemi ActiveAssetDatasetPath provider'ında yapılıyor
            if (savedSchedule != null) {
              try {
                if (_isDisposed) return;
                ref
                    .read(allowConflictsProvider.notifier)
                    .set(savedSchedule.allowConflicts);
                ref
                    .read(minFreeDaysProvider.notifier)
                    .set(savedSchedule.minFreeDays);
              } catch (_) {
                // Ignore provider errors silently
              }
            }
          }
        }
      } else {
        state = const [];
      }
    } catch (e) {
      if (_isDisposed) return;
      state = const [];
    }
  }

  Future<void> saveActiveCourses(
    List<Course> courses, {
    String? scheduleId,
  }) async {
    state = courses;
    final jsonList = courses.map((e) => e.toJson()).toList();
    await storageService.setString(_kKeyActiveSchedule, json.encode(jsonList));

    // Aktif program ID'sini de sakla
    if (scheduleId != null) {
      await storageService.setString(_kKeyActiveScheduleId, scheduleId);
    } else {
      await storageService.remove(_kKeyActiveScheduleId);
    }
  }

  Future<String?> getActiveScheduleId() async {
    return await storageService.getString(_kKeyActiveScheduleId);
  }

  Future<void> clear() async {
    state = const [];
    await storageService.remove(_kKeyActiveSchedule);
    await storageService.remove(_kKeyActiveScheduleId);
  }
}

@Riverpod(keepAlive: true)
class SavedSchedules extends _$SavedSchedules {
  bool _isDisposed = false;
  bool _hasLoaded = false;

  @override
  List<SavedSchedule> build() {
    _isDisposed = false;
    _hasLoaded = false;
    ref.onDispose(() => _isDisposed = true);
    // Provider ilk oluşturulduğunda load'ı çağır
    if (!_hasLoaded) {
      Future.microtask(() => load());
    }
    return const [];
  }

  Future<void> load() async {
    if (_hasLoaded) return;
    _hasLoaded = true;
    try {
      final raw = await storageService.getString(_kKeyItems);
      if (_isDisposed) return;
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List<dynamic>;
        final schedules = decoded
            .map((e) => SavedSchedule.fromJson(e as Map<String, dynamic>))
            .toList();
        state = schedules;
      } else {
        state = const [];
      }
    } catch (e) {
      // Corrupted data durumunda boş liste
      if (_isDisposed) return;
      state = const [];
    }
  }

  Future<void> _save() async {
    final jsonList = state.map((e) => e.toJson()).toList();
    await storageService.setString(_kKeyItems, json.encode(jsonList));
  }

  Future<void> saveSchedule({
    required String name,
    required List<Course> courses,
    required String datasetPath,
    required bool allowConflicts,
    required int? minFreeDays,
    String? datasetName,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final createdAt = DateTime.now();

    // Aktif dataset bilgilerini al
    final currentDataset = ref.read(currentDatasetInfoProvider);

    final s = SavedSchedule(
      id: id,
      name: name,
      courses: courses,
      createdAt: createdAt,
      updatedAt: createdAt,
      datasetPath: datasetPath,
      datasetYear: currentDataset?.year,
      datasetPeriod: currentDataset?.period,
      allowConflicts: allowConflicts,
      minFreeDays: minFreeDays,
    );

    state = [...state, s];
    await _save();
    unawaited(AnalyticsDataService().logScheduleSaved(s, action: 'create'));
  }

  Future<void> updateSchedule(String id, String newName) async {
    final idx = state.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final current = state[idx];
    final updated = SavedSchedule(
      id: id,
      name: newName,
      courses: current.courses,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      datasetPath: current.datasetPath,
      datasetYear: current.datasetYear,
      datasetPeriod: current.datasetPeriod,
    );

    final newState = [...state];
    newState[idx] = updated;
    state = newState;
    await _save();
  }

  // Alias for compatibility
  Future<void> update(
    String id, {
    String? name,
    List<Course>? courses,
    bool? allowConflicts,
    int? minFreeDays,
    String? datasetPath,
  }) async {
    if (name != null && courses == null) {
      await updateSchedule(id, name);
    } else if (courses != null) {
      final idx = state.indexWhere((e) => e.id == id);
      if (idx == -1) return;
      final current = state[idx];

      // Kurslar güncelleniyorsa, aktif dataset bilgilerini al
      final currentDataset = ref.read(currentDatasetInfoProvider);

      final updated = SavedSchedule(
        id: id,
        name: name ?? current.name,
        courses: courses,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
        datasetPath: datasetPath ?? current.datasetPath,
        datasetYear: currentDataset?.year ?? current.datasetYear,
        datasetPeriod: currentDataset?.period ?? current.datasetPeriod,
        allowConflicts: allowConflicts ?? current.allowConflicts,
        minFreeDays: minFreeDays ?? current.minFreeDays,
      );

      final newState = [...state];
      newState[idx] = updated;
      state = newState;
      await _save();
      unawaited(
        AnalyticsDataService().logScheduleSaved(updated, action: 'update'),
      );
    }
  }

  Future<void> deleteSchedule(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  // Alias for compatibility
  Future<void> remove(String id) async {
    await deleteSchedule(id);
  }

  // Compatibility method for saveNew
  Future<void> saveNew(
    String name,
    List<Course> courses, {
    String? datasetYear,
    String? datasetPeriod,
    String? datasetPath,
    required bool allowConflicts,
    required int? minFreeDays,
  }) async {
    await saveSchedule(
      name: name,
      courses: courses,
      datasetPath: datasetPath ?? '',
      allowConflicts: allowConflicts,
      minFreeDays: minFreeDays,
    );
  }
}
