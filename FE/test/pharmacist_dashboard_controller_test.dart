import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/controllers/pharmacist_dashboard_controller.dart';
import 'package:meds_reminder/models/models.dart';
import 'package:meds_reminder/services/medicine_api.dart';
import 'package:meds_reminder/services/pharmacy_api.dart';
import 'package:meds_reminder/services/pharmacy_order_api.dart';

void main() {
  test(
    'initialization and tab reuse do not request cached data again',
    () async {
      const pharmacistId = '507f1f77bcf86cd799439013';
      const pharmacyId = '11111111-1111-4111-8111-111111111111';
      var pharmacyCalls = 0;
      var orderCalls = 0;
      var medicineCalls = 0;

      final pharmacyApi = PharmacyApi(
        client: MockClient((request) async {
          pharmacyCalls += 1;
          if (request.url.path.endsWith('/inventory')) {
            return http.Response(jsonEncode(const []), 200);
          }
          if (request.url.path == '/api/v1/pharmacies') {
            final active = request.url.queryParameters['isActive'] == 'true';
            return http.Response(
              jsonEncode(active ? [_pharmacy(pharmacistId, pharmacyId)] : []),
              200,
            );
          }
          return http.Response(
            jsonEncode(_pharmacy(pharmacistId, pharmacyId)),
            200,
          );
        }),
      );
      final orderApi = PharmacyOrderApi(
        client: MockClient((request) async {
          orderCalls += 1;
          return http.Response(jsonEncode(const []), 200);
        }),
      );
      final medicineApi = MedicineApi(
        client: MockClient((request) async {
          medicineCalls += 1;
          return http.Response(jsonEncode(const []), 200);
        }),
      );
      final controller = PharmacistDashboardController(
        user: const AuthUser(
          id: pharmacistId,
          email: 'pharmacist@example.com',
          fullName: 'Dược sĩ',
          role: AppRole.pharmacist,
        ),
        pharmacyApi: pharmacyApi,
        orderApi: orderApi,
        medicineApi: medicineApi,
      );

    await controller.initialize();
    expect(controller.error, isNull);
    expect(controller.pharmacies, hasLength(1));
      expect(pharmacyCalls, 4); // active + inactive + detail + inventory
      expect(orderCalls, 1);
      expect(medicineCalls, 1);

      await controller.initialize();
      await controller.loadPharmacyDetail(pharmacyId);
      await controller.loadInventory(pharmacyId);
      expect(pharmacyCalls, 4);
      expect(orderCalls, 1);
      expect(medicineCalls, 1);

      await controller.initialize(force: true);
      expect(pharmacyCalls, 8);
      expect(orderCalls, 2);
      expect(medicineCalls, 2);
      controller.dispose();
    },
  );
}

Map<String, dynamic> _pharmacy(String pharmacistId, String pharmacyId) => {
  'id': pharmacyId,
  'pharmacistId': pharmacistId,
  'name': 'An Tam Pharmacy',
  'phoneNumber': '0901234567',
  'addressText': 'District 1',
  'latitude': 10.77,
  'longitude': 106.7,
  'isActive': true,
};
