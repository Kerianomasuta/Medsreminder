import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/screens/patient/schedule_timeline_page.dart';
import 'package:meds_reminder/services/schedule_api.dart';
import 'package:meds_reminder/widgets/app_components.dart';

void main() {
  testWidgets('DayStrip displays all 7 days from T2 to CN and handles tap', (
    tester,
  ) async {
    int? tappedDay;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DayStrip(
            selectedDay: 1, // T2
            onDaySelected: (day) => tappedDay = day,
            badgeCounts: const {1: 2, 3: 1},
          ),
        ),
      ),
    );

    expect(find.text('T2'), findsOneWidget);
    expect(find.text('T3'), findsOneWidget);
    expect(find.text('T4'), findsOneWidget);
    expect(find.text('T5'), findsOneWidget);
    expect(find.text('T6'), findsOneWidget);
    expect(find.text('T7'), findsOneWidget);
    expect(find.text('CN'), findsOneWidget);

    // Tap T3 (Thứ Ba -> day = 2)
    await tester.tap(find.text('T3'));
    await tester.pump();
    expect(tappedDay, 2);

    // Tap CN (Chủ Nhật -> day = 7)
    await tester.tap(find.text('CN'));
    await tester.pump();
    expect(tappedDay, 7);
  });

  testWidgets(
    'ScheduleTimelinePage filters medications based on selected day tab',
    (tester) async {
      final mockData = [
        {
          'id': 'rule-monday-only',
          'prescriptionItemId': 'item-1',
          'patientId': 'patient-123',
          'reminderTime': '08:00:00',
          'daysOfWeek': [1], // Chỉ uống Thứ 2
          'isActive': true,
          'dosagePerTime': 2,
          'instructions': 'Sau ăn',
          'medicine': {
            'id': 'med-1',
            'name': 'Thuốc Chỉ Thứ 2',
            'unit': 'VIEN',
            'imageUrl': null,
          },
          'prescription': {
            'id': 'presc-1',
            'title': 'Đơn A',
            'startDate': '2026-10-01',
            'endDate': '2026-10-31',
            'isActive': true,
          },
        },
        {
          'id': 'rule-tuesday-only',
          'prescriptionItemId': 'item-2',
          'patientId': 'patient-123',
          'reminderTime': '12:00:00',
          'daysOfWeek': [2], // Chỉ uống Thứ 3
          'isActive': true,
          'dosagePerTime': 1,
          'instructions': 'Trước ăn',
          'medicine': {
            'id': 'med-2',
            'name': 'Thuốc Chỉ Thứ 3',
            'unit': 'VIEN',
            'imageUrl': null,
          },
          'prescription': {
            'id': 'presc-2',
            'title': 'Đơn B',
            'startDate': '2026-10-01',
            'endDate': '2026-10-31',
            'isActive': true,
          },
        },
      ];

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ScheduleApi(client: client);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleTimelinePage(
              patientId: 'patient-123',
              api: api,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Click on T2 (Thứ 2)
      await tester.tap(find.text('T2'));
      await tester.pumpAndSettle();

      expect(find.text('Thuốc Chỉ Thứ 2'), findsOneWidget);
      expect(find.text('Thuốc Chỉ Thứ 3'), findsNothing);

      // Click on T3 (Thứ 3)
      await tester.tap(find.text('T3'));
      await tester.pumpAndSettle();

      expect(find.text('Thuốc Chỉ Thứ 3'), findsOneWidget);
      expect(find.text('Thuốc Chỉ Thứ 2'), findsNothing);

      // Click on T4 (Thứ 4 - không có thuốc nào)
      await tester.tap(find.text('T4'));
      await tester.pumpAndSettle();

      expect(find.text('Không có cữ uống nào vào Thứ Tư (T4)'), findsOneWidget);
      expect(find.text('Thuốc Chỉ Thứ 2'), findsNothing);
      expect(find.text('Thuốc Chỉ Thứ 3'), findsNothing);
    },
  );
}
