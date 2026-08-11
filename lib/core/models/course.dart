import 'package:scheduler/core/models/time_slot.dart';

class Course {
  final String id;
  final String code;
  final String name;
  final String section;
  final int credits;
  final String lecturer;
  final String room;
  final String schedule;
  final List<String> timeSlots;
  final TimeSlot timeSlot;
  final String department;
  final String faculty;
  final String semester;
  final String type;
  final int capacity;
  final int enrolled;
  final List<String> prerequisites;
  final String description;

  const Course({
    required this.id,
    required this.code,
    required this.name,
    this.section = '',
    this.credits = 0,
    this.lecturer = '',
    this.room = '',
    this.schedule = '',
    this.timeSlots = const [],
    TimeSlot? timeSlot,
    this.department = '',
    this.faculty = '',
    this.semester = '',
    this.type = '',
    this.capacity = 0,
    this.enrolled = 0,
    this.prerequisites = const [],
    this.description = '',
  }) : timeSlot = timeSlot ?? const TimeSlot(day: '', startHour: 0, endHour: 0);

  Course copyWith({
    String? id,
    String? code,
    String? name,
    String? section,
    int? credits,
    String? lecturer,
    String? room,
    String? schedule,
    List<String>? timeSlots,
    TimeSlot? timeSlot,
    String? department,
    String? faculty,
    String? semester,
    String? type,
    int? capacity,
    int? enrolled,
    List<String>? prerequisites,
    String? description,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      section: section ?? this.section,
      credits: credits ?? this.credits,
      lecturer: lecturer ?? this.lecturer,
      room: room ?? this.room,
      schedule: schedule ?? this.schedule,
      timeSlots: timeSlots ?? this.timeSlots,
      timeSlot: timeSlot ?? this.timeSlot,
      department: department ?? this.department,
      faculty: faculty ?? this.faculty,
      semester: semester ?? this.semester,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      enrolled: enrolled ?? this.enrolled,
      prerequisites: prerequisites ?? this.prerequisites,
      description: description ?? this.description,
    );
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final scheduleString =
        json['Schedule']?.toString() ?? json['schedule']?.toString() ?? '';
    return Course(
      id: json['id']?.toString() ?? json['Section']?.toString() ?? '',
      code: json['Code']?.toString() ?? json['code']?.toString() ?? '',
      name: json['Name']?.toString() ?? json['name']?.toString() ?? '',
      section: json['Section']?.toString() ?? json['section']?.toString() ?? '',
      credits:
          int.tryParse(json['Cr']?.toString() ?? '') ??
          json['credits']?.toInt() ??
          0,
      lecturer:
          json['Lecturer']?.toString() ?? json['lecturer']?.toString() ?? '',
      room: json['Room']?.toString() ?? json['room']?.toString() ?? '',
      schedule: scheduleString,
      timeSlots:
          (json['timeSlots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timeSlot: json['timeSlot'] != null
          ? TimeSlot.fromJson(json['timeSlot'])
          : TimeSlot.fromSchedule(scheduleString),
      department:
          json['Dept.']?.toString() ?? json['department']?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? '',
      semester:
          json['Period']?.toString() ?? json['semester']?.toString() ?? '',
      type: json['Category']?.toString() ?? json['type']?.toString() ?? '',
      capacity:
          int.tryParse(json['# of Students']?.toString() ?? '') ??
          json['capacity']?.toInt() ??
          0,
      enrolled:
          int.tryParse(json['# of Students']?.toString() ?? '') ??
          json['enrolled']?.toInt() ??
          0,
      prerequisites:
          (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'section': section,
      'credits': credits,
      'lecturer': lecturer,
      'room': room,
      'schedule': schedule,
      'timeSlots': timeSlots,
      'timeSlot': timeSlot.toJson(),
      'department': department,
      'faculty': faculty,
      'semester': semester,
      'type': type,
      'capacity': capacity,
      'enrolled': enrolled,
      'prerequisites': prerequisites,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course &&
        other.id == id &&
        other.code == code &&
        other.name == name &&
        other.section == section;
  }

  @override
  int get hashCode {
    return id.hashCode ^ code.hashCode ^ name.hashCode ^ section.hashCode;
  }

  @override
  String toString() {
    return 'Course(id: $id, code: $code, name: $name, section: $section)';
  }
}
