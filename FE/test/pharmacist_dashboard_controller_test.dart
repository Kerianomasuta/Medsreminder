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
}
