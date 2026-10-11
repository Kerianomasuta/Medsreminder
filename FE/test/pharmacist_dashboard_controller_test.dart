import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/controllers/pharmacist_dashboard_controller.dart';
import 'package:meds_reminder/models/models.dart';
import 'package:meds_reminder/services/pharmacy_order_api.dart';

void main() {
  test('dashboard only loads the current pharmacist orders', () async {
    var calls = 0;
    final controller = PharmacistDashboardController(
      user: const AuthUser(
        id: '507f1f77bcf86cd799439013',
        email: 'pharmacist@example.com',
        fullName: 'Dược sĩ',
        role: AppRole.pharmacist,
      ),
      orderApi: PharmacyOrderApi(
        client: MockClient((request) async {
          calls += 1;
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/orders/mine');
          return http.Response(jsonEncode(const []), 200);
        }),
      ),
    );

    await controller.initialize();
    expect(controller.error, isNull);
    expect(controller.orders, isEmpty);
    expect(calls, 1);

    await controller.initialize();
    expect(calls, 1);

    await controller.initialize(force: true);
    expect(calls, 2);
    controller.dispose();
  });

  test('fetchOrdersByStatus calls GET /api/v1/orders and refreshOrders works', () async {
    final requests = <http.Request>[];
    final controller = PharmacistDashboardController(
      user: const AuthUser(
        id: '507f1f77bcf86cd799439013',
        email: 'pharmacist@example.com',
        fullName: 'Dược sĩ',
        role: AppRole.pharmacist,
      ),
      orderApi: PharmacyOrderApi(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode([
              {
                'id': 'ord-1',
                'orderCode': '#MR-001',
                'pharmacyId': 'ph-1',
                'status': 'PENDING_REVIEW',
                'fulfillmentType': 'PICKUP',
                'totalAmount': 50000,
                'createdAt': '2026-10-11T10:00:00.000Z',
                'items': [],
              }
            ]),
            200,
          );
        }),
      ),
    );

    // 1. fetch all (status: null)
    await controller.fetchOrdersByStatus(null);
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
    expect(controller.orders.length, 1);
    expect(controller.orders.first.orderCode, '#MR-001');
    expect(requests.last.url.path, '/api/v1/orders');
    expect(requests.last.url.queryParameters['status'], isNull);

    // 2. fetch by status 'PENDING_REVIEW'
    await controller.fetchOrdersByStatus('PENDING_REVIEW');
    expect(requests.last.url.path, '/api/v1/orders');
    expect(requests.last.url.queryParameters['status'], 'PENDING_REVIEW');

    // 3. refreshOrders keeps current status
    await controller.refreshOrders();
    expect(requests.last.url.queryParameters['status'], 'PENDING_REVIEW');

    // 4. fetch by status 'READY'
    await controller.fetchOrdersByStatus('READY');
    expect(requests.last.url.queryParameters['status'], 'READY');

    // 5. error state handling
    final errorController = PharmacistDashboardController(
      user: const AuthUser(
        id: '507f1f77bcf86cd799439013',
        email: 'pharmacist@example.com',
        fullName: 'Dược sĩ',
        role: AppRole.pharmacist,
      ),
      orderApi: PharmacyOrderApi(
        client: MockClient((_) async => http.Response('Internal Error', 500)),
      ),
    );
    await errorController.fetchOrdersByStatus('PREPARING');
    expect(errorController.error, isNotNull);
    expect(errorController.loading, isFalse);

    controller.dispose();
    errorController.dispose();
  });
}
