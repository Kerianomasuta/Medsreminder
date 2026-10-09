import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/models/pharmacist_dashboard.dart';
import 'package:meds_reminder/services/pharmacy_api.dart';
import 'package:meds_reminder/services/pharmacy_order_api.dart';

const pharmacyId = '11111111-1111-4111-8111-111111111111';
const orderId = '22222222-2222-4222-8222-222222222222';
const pharmacyJson = {
  'id': pharmacyId,
  'pharmacistId': '507f1f77bcf86cd799439013',
  'name': 'An Tam Pharmacy',
  'phoneNumber': '0901234567',
  'addressText': 'District 1',
  'latitude': 10.77,
  'longitude': 106.7,
  'geohash': 'w3gvk1xyz',
  'distanceKm': 1.25,
};
const orderJson = {
  'id': orderId,
  'orderCode': 'MD12345678',
  'pharmacyId': pharmacyId,
  'status': 'PENDING_REVIEW',
  'fulfillmentType': 'PICKUP',
  'totalAmount': 0,
  'createdAt': '2026-10-08T00:00:00.000Z',
  'items': <Map<String, dynamic>>[],
};

void main() {
  test('pharmacy API uses the existing list and detail routes', () async {
    final calls = <http.BaseRequest>[];
    final bodies = <Map<String, dynamic>?>[];
    final client = MockClient((request) async {
      calls.add(request);
      bodies.add(
        request.body.isNotEmpty
            ? jsonDecode(request.body) as Map<String, dynamic>
            : null,
      );
      if (request.method == 'GET' && request.url.path == '/api/v1/pharmacies') {
        return http.Response(jsonEncode([pharmacyJson]), 200);
      }
      return http.Response(jsonEncode(pharmacyJson), 200);
    });
    final api = PharmacyApi(client: client);
    await api.list();
    await api.getById(pharmacyId);

    expect(calls.map((r) => '${r.method} ${r.url.path}'), [
      'GET /api/v1/pharmacies',
      'GET /api/v1/pharmacies/$pharmacyId',
    ]);
    expect(bodies, everyElement(isNull));
  });

  test(
    'pharmacist profile resolves its id then calls the detail route',
    () async {
      final calls = <String>[];
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path == '/api/v1/pharmacies') {
          return http.Response(jsonEncode([pharmacyJson]), 200);
        }
        return http.Response(jsonEncode(pharmacyJson), 200);
      });
      final api = PharmacyApi(client: client);

      final pharmacy = await api.getForPharmacist('507f1f77bcf86cd799439013');

      expect(pharmacy.id, pharmacyId);
      expect(calls, [
        'GET /api/v1/pharmacies',
        'GET /api/v1/pharmacies/$pharmacyId',
      ]);
    },
  );

  test('pharmacy API sends the caregiver geohash and 10 km radius', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(jsonEncode([pharmacyJson]), 200);
    });
    final api = PharmacyApi(client: client);

    final result = await api.list(
      latitude: 10.7769,
      longitude: 106.7009,
      geohash: 'w3gvk1xyz',
      radiusKm: 10,
    );

    expect(requestedUri?.queryParameters, {
      'latitude': '10.7769',
      'longitude': '106.7009',
      'geohash': 'w3gvk1xyz',
      'radiusKm': '10.0',
    });
    expect(result.single.distanceKm, 1.25);
  });

  test(
    'caregiver creates an order without a client supplied caregiver id',
    () async {
      Map<String, dynamic>? body;
      final client = MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(orderJson), 201);
      });
      final api = PharmacyOrderApi(client: client);

      await api.create(
        patientId: '507f1f77bcf86cd799439011',
        pharmacyId: pharmacyId,
        prescriptionId: '44444444-4444-4444-8444-444444444444',
        fulfillmentType: FulfillmentType.pickup,
        items: [
          (
            prescriptionItemId: '55555555-5555-4555-8555-555555555555',
            quantity: 4,
          ),
        ],
      );

      expect(body?['caregiverId'], isNull);
      expect(body?['patientId'], '507f1f77bcf86cd799439011');
      expect(body?['pharmacyId'], pharmacyId);
      expect(body?['fulfillmentType'], 'PICKUP');
      expect((body?['items'] as List).single, {
        'prescriptionItemId': '55555555-5555-4555-8555-555555555555',
        'quantity': 4,
      });
    },
  );

  test('pharmacist order API calls mine and workflow actions', () async {
    final calls = <String>[];
    final bodies = <Map<String, dynamic>?>[];
    final client = MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      bodies.add(
        request.body.isNotEmpty
            ? jsonDecode(request.body) as Map<String, dynamic>
            : null,
      );
      if (request.url.path.endsWith('/mine')) {
        return http.Response(jsonEncode([orderJson]), 200);
      }
      return http.Response(jsonEncode(orderJson), 200);
    });
    final api = PharmacyOrderApi(client: client);

    await api.listMine();
    await api.getById(orderId);
    await api.accept(orderId);
    await api.reject(orderId, 'Hết hàng');
    await api.markReady(orderId);
    await api.ship(orderId, shipperName: 'Minh', shipperPhone: '0900000000');
    await api.cancel(orderId, 'Khách không nhận');

    expect(calls, [
      'GET /api/v1/orders/mine',
      'GET /api/v1/orders/$orderId',
      'POST /api/v1/orders/$orderId/accept',
      'POST /api/v1/orders/$orderId/reject',
      'POST /api/v1/orders/$orderId/ready',
      'POST /api/v1/orders/$orderId/ship',
      'POST /api/v1/orders/$orderId/cancel',
    ]);
    expect(bodies[3]!['rejectionReason'], 'Hết hàng');
    expect(bodies[5]!['shipperPhone'], '0900000000');
  });
}
