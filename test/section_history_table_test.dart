import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/shared/widgets/section_history_table.dart';

void main() {
  testWidgets('SectionHistoryTable shows not-offered row', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionHistoryTable(
            courseCode: 'CS101',
            groups: [
              SectionTermGroup(label: '2024-2025 1. dönem', sections: null),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Bu dönemde açılmadı'), findsOneWidget);
  });

  testWidgets('SectionHistoryTable formats section and renders stats', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionHistoryTable(
            courseCode: 'CMPE421',
            groups: [
              SectionTermGroup(
                label: '2024-2025 1. dönem',
                sections: [
                  SectionRowData(
                    section: 'CMPE421_01',
                    totalStudents: 30,
                    successfull: 25,
                    conditional: 3,
                    unsuccessfull: 2,
                    providedAvgText: '2.70',
                    lecturer: 'Dr A',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('01'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('2.70'), findsOneWidget);
    expect(find.text('Dr A'), findsOneWidget);
  });
}
