import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/medication_logs_api.dart';
import 'package:meds_reminder/services/schedule_api.dart';
import 'package:meds_reminder/widgets/schedule_details_modal.dart';

void main() {
  const ruleId = '3f93b6fd-ac93-461d-8730-685832163395';
  const patientId = '507f1f77bcf86cd799439011';
  final ruleJson = <String, dynamic>{
    'id': ruleId,
    'prescriptionItemId': '462335dd-7350-4dd6-a62a-3652e1d24491',
    'patientId': patientId,
    'reminderTime': '20:30:00',
    'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
    'isActive': true,
    'dosagePerTime': 1,
    'instructions': 'Sau ăn',
    'medicine': {'id': 'medicine-id', 'name': 'Paracetamol', 'unit': 'VIEN'},
    'prescription': {
      'id': 'prescription-id',
      'title': 'Đơn tháng 10',
      'startDate': '2026-10-01',
      'endDate': '2026-10-31',
      'isActive': true,
    },
  };

  testWidgets(
    'detail uses current schedule time and lazy-loads matching medication result',
    (tester) async {
      final scheduleCalls = <String>[];
      final logCalls = <Uri>[];
      final scheduleApi = ScheduleApi(
        client: MockClient((request) async {
          scheduleCalls.add(request.url.path);
          if (request.url.path.endsWith('/$ruleId')) {
            return http.Response(
              jsonEncode(ruleJson),
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8',
              },
            );
          }
          return http.Response(
            jsonEncode([ruleJson]),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final logsApi = MedicationLogsApi(
        client: MockClient((request) async {
          logCalls.add(request.url);
          return http.Response(
            jsonEncode([
              {
                'id': 'log-id',
                'scheduleRuleId': ruleId,
                'patientId': patientId,
                'scheduledAt': '2026-10-09T20:30:00',
                'actualTakenAt': '2026-10-09T20:45:00',
                'status': 'TAKEN',
                'escalationLevel': 0,
              },
              {
                'id': 'unrelated-log',
                'scheduleRuleId': 'another-rule',
                'patientId': patientId,
                'scheduledAt': '2026-10-09T08:00:00',
                'status': 'SKIPPED',
                'skipReason': 'Không được hiển thị',
                'escalationLevel': 0,
              },
            ]),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleDetailsModalSheet(
              scheduleId: ruleId,
              selectedDate: DateTime(2026, 10, 9),
              scheduleApi: scheduleApi,
              medicationLogsApi: logsApi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(scheduleCalls, contains('/api/v1/schedule-rules/$ruleId'));
      expect(logCalls, hasLength(1));
      expect(logCalls.single.path, '/api/v1/medication-logs');
      expect(logCalls.single.queryParameters['from'], '2026-10-09');
      expect(logCalls.single.queryParameters['to'], '2026-10-09');
      expect(logCalls.single.queryParameters['patientId'], patientId);
      expect(find.text('20:30'), findsWidgets);
      expect(find.text('Uống trễ'), findsOneWidget);
      expect(find.textContaining('trễ 15 phút'), findsOneWidget);
      expect(find.textContaining('Không được hiển thị'), findsNothing);
    },
  );

  testWidgets('detail shows skipped status and reason from medication log', (
    tester,
  ) async {
    final scheduleApi = ScheduleApi(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode(
            request.url.path.endsWith('/$ruleId') ? ruleJson : [ruleJson],
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final logsApi = MedicationLogsApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': 'log-id',
              'scheduleRuleId': ruleId,
              'patientId': patientId,
              'scheduledAt': '2026-10-09T20:30:00',
              'status': 'SKIPPED',
              'skipReason': 'Đau dạ dày',
              'escalationLevel': 1,
            },
          ]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDetailsModalSheet(
            scheduleId: ruleId,
            selectedDate: DateTime(2026, 10, 9),
            scheduleApi: scheduleApi,
            medicationLogsApi: logsApi,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã bỏ qua'), findsOneWidget);
    expect(find.text('Lý do: Đau dạ dày'), findsOneWidget);
  });
}
