import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:scheduler/core/config/app_info.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/models/saved_schedule.dart';
import 'package:scheduler/core/services/analytics_consent_store.dart';
import 'package:scheduler/core/services/analytics_identity_service.dart';

class AnalyticsDataService {
  static final AnalyticsDataService _instance = AnalyticsDataService._internal();
  factory AnalyticsDataService() => _instance;
  AnalyticsDataService._internal();

  static const String _eventsCollection = 'analytics_events';
  static const String _usersCollection = 'analytics_users';
  static const String _scheduleSavesCollection = 'schedule_saves';
  static const String _coursePairStatsCollection = 'course_pair_stats';
  static const String _courseStatsCollection = 'course_stats';

  final AnalyticsConsentStore _consentStore = AnalyticsConsentStore();
  final AnalyticsIdentityService _identityService = AnalyticsIdentityService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Duration _selectionDebounceDuration = const Duration(seconds: 2);

  String? _sessionId;
  String? _appVersion;
  String? _lastSelectionSignature;
  Timer? _selectionDebounce;
  _SelectionSnapshot? _pendingSnapshot;

  Future<void> logAppOpen() async {
    if (!await _consentStore.isGranted()) return;
    await _touchUserDocument();
    await logEvent('app_open', const <String, Object?>{});
  }

  Future<void> logEvent(
    String type,
    Map<String, Object?> payload, {
    bool requireConsent = true,
  }) async {
    if (requireConsent && !await _consentStore.isGranted()) return;
    try {
      final base = await _baseContext();
      await _firestore.collection(_eventsCollection).add({
        ...base,
        'type': type,
        'schemaVersion': 1,
        'payload': payload,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtIso': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silent error handling
    }
  }

  Future<void> logCourseSelectionChanged(
    Course course, {
    required bool isAdded,
    String source = 'single',
  }) async {
    if (!await _consentStore.isGranted()) return;
    final payload = <String, Object?>{
      'action': isAdded ? 'add' : 'remove',
      'source': source,
      ..._coursePayload(course),
    };
    await logEvent('course_selection_changed', payload);
  }

  Future<void> logCoursesCleared(int count) async {
    if (!await _consentStore.isGranted()) return;
    await logEvent('courses_cleared', {'course_count': count});
  }

  Future<void> queueSelectionSnapshot(
    List<Course> courses, {
    String? datasetPath,
    String? datasetYear,
    String? datasetPeriod,
    bool? allowConflicts,
    int? minFreeDays,
  }) async {
    if (!await _consentStore.isGranted()) return;
    final keys = _uniqueSorted(courses.map(_courseKey));
    final signature = keys.join('|');
    if (signature == _lastSelectionSignature) return;
    _lastSelectionSignature = signature;

    _pendingSnapshot = _SelectionSnapshot(
      courses: List<Course>.from(courses),
      datasetPath: datasetPath,
      datasetYear: datasetYear,
      datasetPeriod: datasetPeriod,
      allowConflicts: allowConflicts,
      minFreeDays: minFreeDays,
      capturedAt: DateTime.now(),
    );

    _selectionDebounce?.cancel();
    _selectionDebounce = Timer(_selectionDebounceDuration, () {
      unawaited(_flushSelectionSnapshot());
    });
  }

  Future<void> logScheduleSaved(
    SavedSchedule schedule, {
    required String action,
  }) async {
    if (!await _consentStore.isGranted()) return;
    final base = await _baseContext();
    final courses = schedule.courses;
    final courseKeys = _uniqueSorted(courses.map(_courseKey));
    final courseCodes = _uniqueSorted(courses.map((c) => c.code));
    final courseDetails = courses.map(_coursePayload).toList();

    final payload = <String, Object?>{
      ...base,
      'action': action,
      'scheduleId': schedule.id,
      'courseKeys': courseKeys,
      'courseCodes': courseCodes,
      'courseCount': courses.length,
      'courses': courseDetails,
      'datasetPath': schedule.datasetPath,
      'datasetYear': schedule.datasetYear,
      'datasetPeriod': schedule.datasetPeriod,
      'allowConflicts': schedule.allowConflicts,
      'minFreeDays': schedule.minFreeDays,
    };

    try {
      await _firestore.collection(_scheduleSavesCollection).add({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtIso': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silent error handling
    }

    await logEvent('schedule_saved', {
      'action': action,
      'courseCount': courses.length,
      'courseCodes': courseCodes,
      'datasetPath': schedule.datasetPath,
      'datasetYear': schedule.datasetYear,
      'datasetPeriod': schedule.datasetPeriod,
      'allowConflicts': schedule.allowConflicts,
      'minFreeDays': schedule.minFreeDays,
    });

    await _touchUserDocument(
      extra: {
        'lastScheduleSavedAt': FieldValue.serverTimestamp(),
        'lastScheduleSavedAtIso': DateTime.now().toIso8601String(),
        'lastSavedCourseKeys': courseKeys,
        'lastSavedCourseCodes': courseCodes,
        'scheduleSaveCount': FieldValue.increment(1),
      },
    );

    await _incrementCourseSavedCounts(courses);
    await _incrementCoursePairStats(
      courseCodes,
      countField: 'savedTogetherCount',
      lastAtField: 'lastSavedAt',
    );
  }

  Future<void> logScheduleExported({
    required String format,
    required List<Course> courses,
  }) async {
    if (!await _consentStore.isGranted()) return;
    await logEvent('schedule_exported', {
      'format': format,
      'courseCount': courses.length,
      'courseCodes': _uniqueSorted(courses.map((c) => c.code)),
    });
  }

  Future<void> logConflictDetected({
    required List<Course> courses,
    int? conflictCount,
  }) async {
    if (!await _consentStore.isGranted()) return;
    await logEvent('conflict_detected', {
      'conflictCount': conflictCount ?? courses.length,
      'courseCodes': _uniqueSorted(courses.map((c) => c.code)),
    });
  }

  Future<void> submitFeedback({
    required String message,
    required List<Course> selectedCourses,
    String? datasetPath,
    String? datasetYear,
    String? datasetPeriod,
    bool? allowConflicts,
    int? minFreeDays,
    String? locale,
  }) async {
    final base = await _baseContext();
    final courseKeys = _uniqueSorted(selectedCourses.map(_courseKey));
    final courseCodes = _uniqueSorted(selectedCourses.map((c) => c.code));

    final payload = <String, Object?>{
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtIso': DateTime.now().toIso8601String(),
      'locale': locale ?? _currentLocale(),
      'platform': _platformName(),
      'appVersion': await _getAppVersion(),
      'userId': base['userId'],
      'sessionId': base['sessionId'],
      'courseKeys': courseKeys,
      'courseCodes': courseCodes,
      'courseCount': selectedCourses.length,
      'datasetPath': datasetPath,
      'datasetYear': datasetYear,
      'datasetPeriod': datasetPeriod,
      'allowConflicts': allowConflicts,
      'minFreeDays': minFreeDays,
    };

    try {
      await _firestore.collection('feedback').add(payload);
    } catch (_) {
      rethrow;
    }

    if (await _consentStore.isGranted()) {
      await logEvent('feedback_submitted', {
        'courseCount': selectedCourses.length,
        'courseCodes': courseCodes,
      });
    }
  }

  Future<void> _flushSelectionSnapshot() async {
    final snapshot = _pendingSnapshot;
    if (snapshot == null) return;
    _pendingSnapshot = null;

    final courseKeys = _uniqueSorted(snapshot.courses.map(_courseKey));
    final courseCodes = _uniqueSorted(snapshot.courses.map((c) => c.code));

    await _touchUserDocument(
      extra: {
        'lastSelectedAt': FieldValue.serverTimestamp(),
        'lastSelectedAtIso': snapshot.capturedAt.toIso8601String(),
        'lastSelectedCourseKeys': courseKeys,
        'lastSelectedCourseCodes': courseCodes,
        'selectedCourseCount': snapshot.courses.length,
        'datasetPath': snapshot.datasetPath,
        'datasetYear': snapshot.datasetYear,
        'datasetPeriod': snapshot.datasetPeriod,
        'allowConflicts': snapshot.allowConflicts,
        'minFreeDays': snapshot.minFreeDays,
        'selectionSnapshotCount': FieldValue.increment(1),
      },
    );

    await logEvent('selection_snapshot', {
      'courseKeys': courseKeys,
      'courseCodes': courseCodes,
      'courseCount': snapshot.courses.length,
      'datasetPath': snapshot.datasetPath,
      'datasetYear': snapshot.datasetYear,
      'datasetPeriod': snapshot.datasetPeriod,
      'allowConflicts': snapshot.allowConflicts,
      'minFreeDays': snapshot.minFreeDays,
    });

    await _incrementCoursePairStats(
      courseCodes,
      countField: 'selectedTogetherCount',
      lastAtField: 'lastSelectedAt',
    );
  }

  Future<void> _touchUserDocument({Map<String, Object?>? extra}) async {
    try {
      final base = await _baseContext();
      final doc = _firestore.collection(_usersCollection).doc(base['userId'] as String);
      final payload = <String, Object?>{
        ...base,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'lastSeenAtIso': DateTime.now().toIso8601String(),
        ...?extra,
      };

      await doc.set(payload, SetOptions(merge: true));
    } catch (_) {
      // Silent error handling
    }
  }

  Future<Map<String, Object?>> _baseContext() async {
    return <String, Object?>{
      'userId': await _identityService.getOrCreateAnonymousId(),
      'sessionId': _getSessionId(),
      'appVersion': await _getAppVersion(),
      'platform': _platformName(),
      'locale': _currentLocale(),
    };
  }

  String _getSessionId() {
    if (_sessionId != null) return _sessionId!;
    final now = DateTime.now();
    _sessionId =
        "sess_${now.microsecondsSinceEpoch}_${now.millisecond.toString().padLeft(3, '0')}";
    return _sessionId!;
  }

  Future<String> _getAppVersion() async {
    if (_appVersion != null) return _appVersion!;
    _appVersion = await AppInfo.version;
    return _appVersion!;
  }

  String _currentLocale() {
    return PlatformDispatcher.instance.locale.toLanguageTag();
  }

  String _platformName() {
    return kIsWeb ? 'web' : defaultTargetPlatform.name;
  }

  String _courseKey(Course course) {
    if (course.section.isNotEmpty) {
      return '${course.code}-${course.section}';
    }
    return course.code;
  }

  Map<String, Object?> _coursePayload(Course course) {
    return <String, Object?>{
      'code': course.code,
      if (course.section.isNotEmpty) 'section': course.section,
      if (course.name.isNotEmpty) 'name': course.name,
      if (course.department.isNotEmpty) 'department': course.department,
      if (course.faculty.isNotEmpty) 'faculty': course.faculty,
    };
  }

  List<String> _uniqueSorted(Iterable<String> items) {
    final set = <String>{};
    for (final item in items) {
      if (item.isNotEmpty) {
        set.add(item);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _incrementCourseSavedCounts(List<Course> courses) async {
    if (courses.isEmpty) return;
    final unique = _uniqueCourses(courses);
    if (unique.isEmpty) return;

    final batch = _firestore.batch();
    for (final course in unique) {
      final doc = _firestore.collection(_courseStatsCollection).doc(_courseKey(course));
      batch.set(
        doc,
        <String, Object?>{
          ..._coursePayload(course),
          'savedCount': FieldValue.increment(1),
          'lastSavedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    try {
      await batch.commit();
    } catch (_) {
      // Silent error handling
    }
  }

  Future<void> _incrementCoursePairStats(
    List<String> courseCodes, {
    required String countField,
    required String lastAtField,
  }) async {
    if (courseCodes.length < 2) return;

    final codes = _uniqueSorted(courseCodes);
    if (codes.length < 2) return;

    final pairs = <_CoursePair>[];
    for (var i = 0; i < codes.length - 1; i++) {
      for (var j = i + 1; j < codes.length; j++) {
        pairs.add(_CoursePair(codes[i], codes[j]));
      }
    }

    if (pairs.isEmpty) return;

    const maxOps = 400;
    WriteBatch batch = _firestore.batch();
    var opCount = 0;

    Future<void> commitBatch() async {
      if (opCount == 0) return;
      await batch.commit();
      batch = _firestore.batch();
      opCount = 0;
    }

    try {
      for (final pair in pairs) {
        if (opCount >= maxOps) {
          await commitBatch();
        }
        final doc = _firestore.collection(_coursePairStatsCollection).doc(pair.key);
        batch.set(
          doc,
          <String, Object?>{
            'courseA': pair.a,
            'courseB': pair.b,
            countField: FieldValue.increment(1),
            lastAtField: FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        opCount++;
      }
      await commitBatch();
    } catch (_) {
      // Silent error handling
    }
  }

  Set<Course> _uniqueCourses(List<Course> courses) {
    final seen = <String>{};
    final unique = <Course>{};
    for (final course in courses) {
      final key = _courseKey(course);
      if (seen.add(key)) {
        unique.add(course);
      }
    }
    return unique;
  }
}

class _SelectionSnapshot {
  final List<Course> courses;
  final String? datasetPath;
  final String? datasetYear;
  final String? datasetPeriod;
  final bool? allowConflicts;
  final int? minFreeDays;
  final DateTime capturedAt;

  const _SelectionSnapshot({
    required this.courses,
    required this.datasetPath,
    required this.datasetYear,
    required this.datasetPeriod,
    required this.allowConflicts,
    required this.minFreeDays,
    required this.capturedAt,
  });
}

class _CoursePair {
  final String a;
  final String b;
  const _CoursePair(this.a, this.b);

  String get key {
    final ordered = [a, b]..sort();
    return '${ordered.first}__${ordered.last}';
  }
}
