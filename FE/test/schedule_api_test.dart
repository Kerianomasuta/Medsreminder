import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/schedule_api.dart';

void main() {
  const scheduleJson = {
    'id': '3f93b6fd-ac93-461d-8730-685832163395',
    'prescriptionItemId': '462335dd-7350-4dd6-a62a-3652e1d24491',
    'patientId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
    'reminderTime': '08:00:00',
    'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
    'isActive': false,
    'dosagePerTime': 1,
    'instructions': 'Sau ăn',
    'medicine': {
      'id': '8514a84b-3a43-4e49-bc67-3b204db50734',
      'name': 'Naruto Uzumaki',
      'unit': 'VIEN',
      'imageUrl': 'https://example.com/paracetamol.png',
    },
    'prescription': {
      'id': 'd40ea2a1-da2c-4804-b307-e76ed60f5182',
      'title': 'Đơn tháng 10',
      'startDate': '2026-10-01',
      'endDate': '2026-10-31',
      'isActive': true,
    },
  };

  test('calls GET all schedule rules and GET schedule rule by ID', () async {
    final calls = <String>[];
    final client = MockClient((request) async {
      calls.add(
        '${request.method} ${request.url.path}${request.url.hasQuery ? '?${request.url.query}' : ''}',
      );
      if (request.method == 'GET' &&
          request.url.path == '/api/v1/schedule-rules') {
        return http.Response(
          jsonEncode([scheduleJson]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(
        jsonEncode(scheduleJson),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final api = ScheduleApi(client: client);

    final list = await api.list(patientId: '3fa85f64-5717-4562-b3fc-2c963f66afa6');
    expect(list.length, 1);
    expect(list.first.id, '3f93b6fd-ac93-461d-8730-685832163395');
    expect(list.first.medicine.name, 'Naruto Uzumaki');
    expect(list.first.displayTime, '08:00');
    expect(list.first.period, 'Sáng');
    expect(list.first.prescription.title, 'Đơn tháng 10');

    final rule = await api.getById('3f93b6fd-ac93-461d-8730-685832163395');
    expect(rule.id, '3f93b6fd-ac93-461d-8730-685832163395');
    expect(rule.isActive, false);
    expect(rule.dosagePerTime, 1.0);
    expect(rule.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);

    expect(calls, [
      'GET /api/v1/schedule-rules?patientId=3fa85f64-5717-4562-b3fc-2c963f66afa6',
      'GET /api/v1/schedule-rules/3f93b6fd-ac93-461d-8730-685832163395',
    ]);
  });

  test('calls PATCH schedule rule to update reminderTime, daysOfWeek, and isActive', () async {
    final calls = <String>[];
    final requestBodies = <Map<String, dynamic>>[];

    final client = MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      if (request.body.isNotEmpty) {
        requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      }
      return http.Response(
        jsonEncode({
          ...scheduleJson,
          'reminderTime': '20:00:00',
          'daysOfWeek': [1, 2, 3, 4, 5],
          'isActive': true,
        }),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final api = ScheduleApi(client: client);

    final updated = await api.update(
      '3f93b6fd-ac93-461d-8730-685832163395',
      reminderTime: '20:00',
      daysOfWeek: [1, 2, 3, 4, 5],
      isActive: true,
    );

    expect(calls, ['PATCH /api/v1/schedule-rules/3f93b6fd-ac93-461d-8730-685832163395']);
    expect(requestBodies.first, {
      'reminderTime': '20:00',
      'daysOfWeek': [1, 2, 3, 4, 5],
      'isActive': true,
    });
    expect(updated.reminderTime, '20:00:00');
    expect(updated.displayTime, '20:00');
    expect(updated.daysOfWeek, [1, 2, 3, 4, 5]);
    expect(updated.isActive, true);
  });

  test('calls POST prescription-items/:id/schedules to create a new dose time', () async {
    final calls = <String>[];
    final requestBodies = <Map<String, dynamic>>[];

    final client = MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      if (request.body.isNotEmpty) {
        requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      }
      return http.Response(
        jsonEncode({
          ...scheduleJson,
          'id': 'new-schedule-id',
          'reminderTime': '20:00:00',
          'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
          'isActive': true,
        }),
        201,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final api = ScheduleApi(client: client);

    final created = await api.create(
      '462335dd-7350-4dd6-a62a-3652e1d24491',
      reminderTime: '20:00',
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
    );

    expect(calls, [
      'POST /api/v1/prescription-items/462335dd-7350-4dd6-a62a-3652e1d24491/schedules',
    ]);
    expect(requestBodies.first, {
      'reminderTime': '20:00',
      'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
    });
    expect(created.id, 'new-schedule-id');
    expect(created.prescriptionItemId, '462335dd-7350-4dd6-a62a-3652e1d24491');
    expect(created.displayTime, '20:00');
  });
}
