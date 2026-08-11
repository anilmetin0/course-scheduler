import 'dart:convert';
import 'package:flutter/services.dart';
// JSON-only implementation
import 'package:scheduler/core/models/course.dart';

class CourseService {
  static CourseService? _instance;
  CourseService._internal();

  factory CourseService() {
    _instance ??= CourseService._internal();
    return _instance!;
  }

  List<Course>? _cachedCourses;
  String? _cachedKey; // distinguish between datasets

  Future<List<Course>> loadCourses({String cacheKey = 'assets'}) async {
    if (_cachedCourses != null && _cachedKey == cacheKey) {
      return _cachedCourses!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/courses.json',
      );

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> coursesJson = jsonMap['courses'] as List<dynamic>;

      _cachedCourses = coursesJson
          .map(
            (courseJson) => Course.fromJson(courseJson as Map<String, dynamic>),
          )
          .where(
            (course) => course.schedule.isNotEmpty,
          ) // Sadece programı olan dersler
          .toList();
      _cachedKey = cacheKey;

      return _cachedCourses!;
    } catch (e) {
      return [];
    }
  }

  List<Course> searchCourses(String query) {
    if (_cachedCourses == null) return [];

    if (query.isEmpty) return _cachedCourses!;

    final lowercaseQuery = query.toLowerCase();
    return _cachedCourses!
        .where(
          (course) =>
              course.code.toLowerCase().contains(lowercaseQuery) ||
              course.name.toLowerCase().contains(lowercaseQuery) ||
              course.lecturer.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  List<Course> getCoursesForDay(String day) {
    if (_cachedCourses == null) return [];

    return _cachedCourses!
        .where((course) => course.timeSlot.day == day)
        .toList();
  }

  List<Course> getCoursesByTime(String day, int hour) {
    if (_cachedCourses == null) return [];

    return _cachedCourses!.where((course) {
      final timeSlot = course.timeSlot;
      return timeSlot.day == day &&
          timeSlot.startHour <= hour &&
          timeSlot.endHour > hour;
    }).toList();
  }

  List<String> getDepartments() {
    if (_cachedCourses == null) return [];

    final departments = _cachedCourses!
        .map((course) => course.department)
        .where((dept) => dept.isNotEmpty)
        .toSet()
        .toList();

    departments.sort();
    return departments;
  }

  List<Course> getCoursesByDepartment(String department) {
    if (_cachedCourses == null) return [];

    return _cachedCourses!
        .where((course) => course.department == department)
        .toList();
  }

  Future<List<Course>> loadCoursesFromString(
    String jsonString, {
    String cacheKey = 'inline',
  }) async {
    if (_cachedCourses != null && _cachedKey == cacheKey) {
      return _cachedCourses!;
    }

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> coursesJson = jsonMap['courses'] as List<dynamic>;

      _cachedCourses = coursesJson
          .map(
            (courseJson) => Course.fromJson(courseJson as Map<String, dynamic>),
          )
          .where((course) => course.schedule.isNotEmpty)
          .toList();
      _cachedKey = cacheKey;
      return _cachedCourses!;
    } catch (e) {
      return [];
    }
  }

  void clearCache() {
    _cachedCourses = null;
    _cachedKey = null;
  }

  // Excel parsing removed — JSON only
}
