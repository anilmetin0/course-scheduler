import 'package:scheduler/core/models/course.dart';

List<String> buildExportLines(List<Course> courses) {
  final sections =
      courses
          .map((c) => c.section.isNotEmpty ? c.section : c.code)
          .toSet()
          .toList()
        ..sort();
  return sections;
}

String buildExportText(List<Course> courses) {
  return buildExportLines(courses).join('\n');
}
