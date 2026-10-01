import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/models/medicine.dart';
import 'package:meds_reminder/services/medicine_api.dart';

void main() {
  const medicineJson = {
    'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
    'name': 'Panadol',
    'genericName': 'Paracetamol',
    'unit': 'VIEN',
    'instructionNote': 'Uống sau ăn',
    'imageUrl': null,
  };

  test('calls all four medicine endpoints with the BE contract', () async {
    final calls = <String>[];
    final requestBodies = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      calls.add(
        '${request.method} ${request.url.path}${request.url.hasQuery ? '?${request.url.query}' : ''}',
      );
      if (request.method == 'GET' && request.url.path == '/api/v1/medicines') {
        return http.Response(
          jsonEncode([medicineJson]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.body.isNotEmpty) {
        requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      }
      return http.Response(
        jsonEncode(medicineJson),
        request.method == 'POST' ? 201 : 200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = MedicineApi(client: client);
    const input = MedicineInput(
      name: 'Panadol',
      genericName: 'Paracetamol',
      unit: MedicineUnit.vien,
      instructionNote: 'Uống sau ăn',
    );

    await api.list(search: 'para');
    await api.getById(medicineJson['id']!);
    await api.create(input);
    await api.update(medicineJson['id']!, input);

    expect(calls, [
      'GET /api/v1/medicines?search=para',
      'GET /api/v1/medicines/${medicineJson['id']}',
      'POST /api/v1/medicines',
      'PATCH /api/v1/medicines/${medicineJson['id']}',
    ]);
    expect(requestBodies, hasLength(2));
    expect(requestBodies, everyElement(isNot(contains('imageUrl'))));
  });
}
