import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/models/medication_log.dart';
import 'package:meds_reminder/services/medication_logs_api.dart';

const logId = '3fa85f64-5717-4562-b3fc-2c963f66afa6';
const patientId = '507f1f77bcf86cd799439011';

Map<String, dynamic> logJson({String status = 'SCHEDULED'}) => {
  'id': logId,
  'scheduleRuleId': '5fa85f64-5717-4562-b3fc-2c963f66afa6',
  'patientId': patientId,
  'scheduledAt': '2026-10-08T01:00:00.000Z',
  'actualTakenAt': status == 'TAKEN' ? '2026-10-08T01:05:00.000Z' : null,
  'status': status,
  'snoozeUntil': status == 'SNOOZED' ? '2026-10-08T01:10:00.000Z' : null,
  'escalationLevel': status == 'MISSED' || status == 'SKIPPED' ? 1 : 0,
  'skipReason': status == 'SKIPPED' ? 'Buồn nôn' : null,
  'dosagePerTime': 2,
  'instructions': 'Sau ăn',
  'medicine': {
    'name': 'Paracetamol',
    'genericName': 'Acetaminophen',
    'unit': 'VIEN',
    'imageUrl': null,
  },
};

void main() {
  test('lists medication logs for an inclusive date range', () async {
    late http.Request sent;
    final api = MedicationLogsApi(
      client: MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode([logJson()]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await api.list(
      from: DateTime(2026, 10, 8),
      to: DateTime(2026, 10, 14),
    );

    expect(sent.method, 'GET');
    expect(sent.url.path, '/api/v1/medication-logs');
    expect(sent.url.queryParameters, {
      'from': '2026-10-08',
      'to': '2026-10-14',
    });
    expect(result.single.status, DoseStatus.scheduled);
    expect(result.single.medicine?.name, 'Paracetamol');
    expect(
      result.single.scheduledAt.toUtc(),
      DateTime.parse('2026-10-08T01:00:00.000Z'),
    );
  });

  test('sends the selected patient id when a caregiver lists logs', () async {
    late http.Request sent;
    final api = MedicationLogsApi(
      client: MockClient((request) async {
        sent = request;
        return http.Response(
          '[]',
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await api.list(
      from: DateTime(2026, 10, 8),
      to: DateTime(2026, 10, 14),
      patientId: patientId,
    );

    expect(sent.url.queryParameters['patientId'], patientId);
  });

  test(
    'calls all four medication log actions with the expected bodies',
    () async {
      final calls = <String>[];
      final bodies = <Map<String, dynamic>>[];
      final api = MedicationLogsApi(
        client: MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          final status = request.url.path.endsWith('/taken')
              ? 'TAKEN'
              : request.url.path.endsWith('/snooze')
              ? 'SNOOZED'
              : request.url.path.endsWith('/skip')
              ? 'SKIPPED'
              : 'MISSED';
          return http.Response(
            jsonEncode(logJson(status: status)),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      await api.markTaken(logId);
      await api.snooze(logId, minutes: 10);
      await api.skip(logId, reason: '  Buồn nôn  ');
      await api.markMissed(logId);

      expect(calls, [
        'POST /api/v1/medication-logs/$logId/taken',
        'POST /api/v1/medication-logs/$logId/snooze',
        'POST /api/v1/medication-logs/$logId/skip',
        'POST /api/v1/medication-logs/$logId/missed',
      ]);
      expect(bodies, [
        <String, dynamic>{},
        {'minutes': 10},
        {'skipReason': 'Buồn nôn'},
        <String, dynamic>{},
      ]);
    },
  );

  test('rejects unsupported snooze duration before sending a request', () {
    final api = MedicationLogsApi(
      client: MockClient((_) async => http.Response('{}', 500)),
    );

    expect(
      () => api.snooze(logId, minutes: 15),
      throwsA(isA<MedicationLogsApiException>()),
    );
  });
}
