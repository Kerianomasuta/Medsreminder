import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/models/pharmacist_dashboard.dart';
import 'package:meds_reminder/services/pharmacy_api.dart';
import 'package:meds_reminder/services/pharmacy_order_api.dart';

const pharmacyId = '11111111-1111-4111-8111-111111111111';
const orderId = '22222222-2222-4222-8222-222222222222';
const medicineId = '33333333-3333-4333-8333-333333333333';
const pharmacyJson = {
  'id': pharmacyId,
  'pharmacistId': '507f1f77bcf86cd799439013',
  'name': 'An Tam Pharmacy',
  'phoneNumber': '0901234567',
  'addressText': 'District 1',
  'latitude': 10.77,
  'longitude': 106.7,
  'isActive': true,
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
  test(
    'pharmacy API uses all six backend routes and expected payloads',
    () async {
      final calls = <http.BaseRequest>[];
      final bodies = <Map<String, dynamic>?>[];
      final client = MockClient((request) async {
        calls.add(request);
        bodies.add(
          request.body.isNotEmpty
              ? jsonDecode(request.body) as Map<String, dynamic>
              : null,
        );
        if (request.url.path.endsWith('/inventory')) {
          return http.Response(
            jsonEncode([
              {
                'id': 'inventory-1',
                'pharmacyId': pharmacyId,
                'medicineId': medicineId,
                'stockQuantity': 12,
                'pricePerUnit': 15000,
              },
            ]),
            200,
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/api/v1/pharmacies') {
          return http.Response(jsonEncode([pharmacyJson]), 200);
        }
        return http.Response(jsonEncode(pharmacyJson), 200);
      });
      final api = PharmacyApi(client: client);
      const input = PharmacyInput(
        pharmacistId: '507f1f77bcf86cd799439013',
        name: 'Nhà thuốc An Tâm',
        phoneNumber: '0901234567',
        addressText: 'Quận 1',
        latitude: 10.77,
        longitude: 106.7,
        isActive: true,
      );

      await api.create(input);
      await api.list(isActive: true);
      await api.getById(pharmacyId);
      await api.update(pharmacyId, input);
      await api.listInventory(pharmacyId);
      await api.upsertInventory(pharmacyId, const [
        InventoryInput(
          medicineId: medicineId,
          stockQuantity: 12,
          pricePerUnit: 15000,
        ),
      ]);

      expect(calls.map((r) => '${r.method} ${r.url.path}'), [
        'POST /api/v1/pharmacies',
        'GET /api/v1/pharmacies',
        'GET /api/v1/pharmacies/$pharmacyId',
        'PATCH /api/v1/pharmacies/$pharmacyId',
        'GET /api/v1/pharmacies/$pharmacyId/inventory',
        'PUT /api/v1/pharmacies/$pharmacyId/inventory',
      ]);
      expect(calls[1].url.queryParameters['isActive'], 'true');
      expect(bodies[0]!['pharmacistId'], '507f1f77bcf86cd799439013');
      expect(bodies[3]!.containsKey('pharmacistId'), isFalse);
      expect((bodies[5]!['items'] as List).single['medicineId'], medicineId);
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
