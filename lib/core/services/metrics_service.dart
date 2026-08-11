import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/services/analytics_consent_store.dart';

class MetricsService {
  static final MetricsService _instance = MetricsService._internal();
  factory MetricsService() => _instance;
  MetricsService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  final AnalyticsConsentStore _consentStore = AnalyticsConsentStore();

  Future<bool> _isEnabled() async => await _consentStore.isGranted();

  String _courseKey(Course course) {
    if (course.section.isNotEmpty) {
      return '${course.code}-${course.section}';
    }
    return course.code;
  }

  Map<String, Object?> _courseBase(Course course) {
    return <String, Object?>{
      'code': course.code,
      if (course.section.isNotEmpty) 'section': course.section,
      if (course.name.isNotEmpty) 'name': course.name,
      if (course.department.isNotEmpty) 'department': course.department,
      if (course.faculty.isNotEmpty) 'faculty': course.faculty,
    };
  }

  Future<void> logCourseAdded(Course course) async {
    if (!await _isEnabled()) return;
    await _firestore.collection('course_stats').doc(_courseKey(course)).set(
      <String, Object?>{
        ..._courseBase(course),
        'addedCount': FieldValue.increment(1),
        'lastAddedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> logCourseRemoved(Course course) async {
    if (!await _isEnabled()) return;
    await _firestore.collection('course_stats').doc(_courseKey(course)).set(
      <String, Object?>{
        ..._courseBase(course),
        'removedCount': FieldValue.increment(1),
        'lastRemovedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> logCoursesAdded(Iterable<Course> courses) async {
    if (!await _isEnabled()) return;
    final unique = _uniqueCourses(courses);
    if (unique.isEmpty) return;

    final batch = _firestore.batch();
    for (final course in unique) {
      final doc = _firestore.collection('course_stats').doc(_courseKey(course));
      batch.set(
        doc,
        <String, Object?>{
          ..._courseBase(course),
          'addedCount': FieldValue.increment(1),
          'lastAddedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> logCoursesRemoved(Iterable<Course> courses) async {
    if (!await _isEnabled()) return;
    final unique = _uniqueCourses(courses);
    if (unique.isEmpty) return;

    final batch = _firestore.batch();
    for (final course in unique) {
      final doc = _firestore.collection('course_stats').doc(_courseKey(course));
      batch.set(
        doc,
        <String, Object?>{
          ..._courseBase(course),
          'removedCount': FieldValue.increment(1),
          'lastRemovedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> logConflictForCourses(Iterable<Course> courses) async {
    if (!await _isEnabled()) return;
    final unique = _uniqueCourses(courses);
    if (unique.isEmpty) return;

    final batch = _firestore.batch();
    for (final course in unique) {
      final doc = _firestore.collection('course_stats').doc(_courseKey(course));
      batch.set(
        doc,
        <String, Object?>{
          ..._courseBase(course),
          'conflictCount': FieldValue.increment(1),
          'lastConflictAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Set<Course> _uniqueCourses(Iterable<Course> courses) {
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
