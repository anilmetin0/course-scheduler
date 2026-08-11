import 'package:scheduler/core/models/course.dart';

class SavedSchedule {
  final String id;
  final String name;
  final List<Course> courses;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String description;
  final String? datasetYear;
  final String? datasetPeriod;
  final String? datasetPath;
  // User preference snapshot when saved
  final bool allowConflicts;
  final int? minFreeDays;

  const SavedSchedule({
    required this.id,
    required this.name,
    required this.courses,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.datasetYear,
    this.datasetPeriod,
    this.datasetPath,
    this.allowConflicts = false,
    this.minFreeDays,
  });

  SavedSchedule copyWith({
    String? id,
    String? name,
    List<Course>? courses,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? datasetYear,
    String? datasetPeriod,
    String? datasetPath,
    bool? allowConflicts,
    int? minFreeDays,
  }) {
    return SavedSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      courses: courses ?? this.courses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      datasetYear: datasetYear ?? this.datasetYear,
      datasetPeriod: datasetPeriod ?? this.datasetPeriod,
      datasetPath: datasetPath ?? this.datasetPath,
      allowConflicts: allowConflicts ?? this.allowConflicts,
      minFreeDays: minFreeDays ?? this.minFreeDays,
    );
  }

  factory SavedSchedule.fromJson(Map<String, dynamic> json) {
    return SavedSchedule(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      courses:
          (json['courses'] as List<dynamic>?)
              ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      description: json['description']?.toString() ?? '',
      datasetYear: json['datasetYear']?.toString(),
      datasetPeriod: json['datasetPeriod']?.toString(),
      datasetPath: json['datasetPath']?.toString(),
      allowConflicts: (json.containsKey('allowConflicts')
              ? json['allowConflicts']
              : json['allow_conflicts']) == true,
      minFreeDays: json['minFreeDays'] is int
          ? json['minFreeDays'] as int
          : json['min_free_days'] is int
              ? json['min_free_days'] as int
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'courses': courses.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
      'datasetYear': datasetYear,
      'datasetPeriod': datasetPeriod,
      'datasetPath': datasetPath,
      'allowConflicts': allowConflicts,
      'minFreeDays': minFreeDays,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedSchedule && other.id == id && other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode;
  }

  @override
  String toString() {
    return 'SavedSchedule(id: $id, name: $name, courses: ${courses.length})';
  }
}
