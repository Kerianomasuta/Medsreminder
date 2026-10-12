import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/screens/patient/schedule_timeline_page.dart';
import 'package:meds_reminder/services/schedule_api.dart';

void main() {
  testWidgets('schedule list filters active and inactive rules', (
    tester,
  ) async {
    final today = DateTime.now().weekday;
    Map<String, dynamic> rule(String id, String name, bool isActive) => {
      'id': id,
      'prescriptionItemId': 'item-$id',
      'patientId': 'patient-123',
      'reminderTime': isActive ? '08:00:00' : '18:00:00',
      'daysOfWeek': [today],
      'isActive': isActive,
      'dosagePerTime': 1,
      'medicine': {'id': 'med-$id', 'name': name, 'unit': 'VIEN'},
      'prescription': {
        'id': 'prescription-$id',
        'title': 'Đơn thuốc',
        'startDate': '2026-01-01',
        'endDate': '2026-12-31',
        'isActive': true,
      },
    };
    final api = ScheduleApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            rule('active', 'Thuốc đang bật', true),
            rule('inactive', 'Thuốc đã tắt', false),
          ]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleTimelinePage(patientId: 'patient-123', api: api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thuốc đang bật'), findsOneWidget);
    expect(find.text('Thuốc đã tắt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('schedule-status-active')));
    await tester.pumpAndSettle();
    expect(find.text('Thuốc đang bật'), findsOneWidget);
    expect(find.text('Thuốc đã tắt'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('schedule-status-inactive')));
    await tester.pumpAndSettle();
    expect(find.text('Thuốc đang bật'), findsNothing);
    expect(find.text('Thuốc đã tắt'), findsOneWidget);
  });
}
