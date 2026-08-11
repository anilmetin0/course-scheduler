import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/core/utils/export_format.dart';

void main() {
  test('buildExportLines uses section when present and sorts unique lines', () {
    final courses = [
      const Course(
        id: '1',
        code: 'CS101',
        name: 'Intro',
        section: 'CS101_02',
        schedule: 'Mo 9-10',
      ),
      const Course(
        id: '2',
        code: 'MATH200',
        name: 'Math',
        section: '',
        schedule: 'Tu 9-10',
      ),
      const Course(
        id: '3',
        code: 'CS101',
        name: 'Intro',
        section: 'CS101_01',
        schedule: 'We 9-10',
      ),
      const Course(
        id: '4',
        code: 'CS101',
        name: 'Intro',
        section: 'CS101_02',
        schedule: 'Th 9-10',
      ),
    ];

    final lines = buildExportLines(courses);

    expect(lines, ['CS101_01', 'CS101_02', 'MATH200']);
  });

  test('buildExportText joins lines with newlines', () {
    final courses = [
      const Course(
        id: '1',
        code: 'CS101',
        name: 'Intro',
        section: 'CS101_02',
        schedule: 'Mo 9-10',
      ),
      const Course(
        id: '2',
        code: 'MATH200',
        name: 'Math',
        section: '',
        schedule: 'Tu 9-10',
      ),
    ];

    final text = buildExportText(courses);

    expect(text, 'CS101_02\nMATH200');
  });
}
