import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/controllers/pharmacist_dashboard_controller.dart';
import 'package:meds_reminder/models/models.dart';
import 'package:meds_reminder/screens/pharmacist/pharmacist_home.dart';
import 'package:meds_reminder/services/geocoding_api.dart';
import 'package:meds_reminder/services/medicine_api.dart';
import 'package:meds_reminder/services/pharmacy_api.dart';
import 'package:meds_reminder/services/pharmacy_order_api.dart';

void main() {
  testWidgets('pharmacy form closes without using disposed controllers', (
    tester,
  ) async {
    const pharmacistId = '507f1f77bcf86cd799439013';
    const pharmacyId = '11111111-1111-4111-8111-111111111111';
    final controller = PharmacistDashboardController(
      user: const AuthUser(
        id: pharmacistId,
        email: 'pharmacist@example.com',
        fullName: 'Dược sĩ',
        role: AppRole.pharmacist,
      ),
      pharmacyApi: PharmacyApi(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode({
                'id': pharmacyId,
                'pharmacistId': pharmacistId,
                'name': 'Nhà thuốc An Tâm',
                'phoneNumber': '0901234567',
                'addressText': 'Quận 1',
                'latitude': 10.77,
                'longitude': 106.7,
                'isActive': true,
              }),
              201,
              headers: const {
                'content-type': 'application/json; charset=utf-8',
              },
            );
          }
          return http.Response('[]', 200);
        }),
      ),
      orderApi: PharmacyOrderApi(
        client: MockClient((_) async => http.Response('[]', 200)),
      ),
      medicineApi: MedicineApi(
        client: MockClient((_) async => http.Response('[]', 200)),
      ),
    );
    await controller.initialize();
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PharmacistHome(
            tab: 4,
            controller: controller,
            geocodingApi: GeocodingApi(
              client: MockClient(
                (_) async => http.Response(
                  jsonEncode([
                    {
                      'display_name': 'Quận 1, TP. Hồ Chí Minh',
                      'lat': '10.77',
                      'lon': '106.7',
                    },
                  ]),
                  200,
                  headers: const {
                    'content-type': 'application/json; charset=utf-8',
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Đăng ký nhà thuốc'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Tên nhà thuốc'),
      'Nhà thuốc An Tâm',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Số điện thoại'),
      '0901234567',
    );
    await tester.enterText(
      find.byKey(const Key('pharmacy-address-search')),
      'Quận 1',
    );
    await tester.tap(find.byKey(const Key('search-pharmacy-address')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('address-result-0')));
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.selectedPharmacyId, pharmacyId);
  });
}
