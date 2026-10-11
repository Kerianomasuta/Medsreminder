import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/controllers/care_network_controller.dart';
import 'package:meds_reminder/models/app_role.dart';
import 'package:meds_reminder/models/auth_user.dart';
import 'package:meds_reminder/models/care_network.dart';
import 'package:meds_reminder/models/prescription.dart';
import 'package:meds_reminder/screens/caregiver/caregiver_pharmacy_screen.dart';
import 'package:meds_reminder/services/device_location_service.dart';
import 'package:meds_reminder/services/pharmacy_api.dart';
import 'package:meds_reminder/services/pharmacy_order_api.dart';
import 'package:meds_reminder/utils/geohash.dart';

const _patientId = '507f1f77bcf86cd799439011';
const _pharmacyId = '11111111-1111-4111-8111-111111111111';
const _prescriptionId = '44444444-4444-4444-8444-444444444444';
const _prescriptionItemId = '55555555-5555-4555-8555-555555555555';

class _FixedLocationProvider implements DeviceLocationProvider {
  const _FixedLocationProvider();

  @override
  Future<DeviceLocation> currentLocation() async =>
      const DeviceLocation(latitude: 10.7769, longitude: 106.7009);
}

class _TestCareNetworkController extends CareNetworkController {
  _TestCareNetworkController(this.bundle)
    : super(
        user: const AuthUser(
          id: '507f1f77bcf86cd799439012',
          email: 'caregiver@example.com',
          fullName: 'Caregiver',
          role: AppRole.caregiver,
        ),
      ) {
    selectedPatientId = _patientId;
  }

  final PatientBundle bundle;

  @override
  PatientBundle? bundleFor(String? patientId) =>
      patientId == _patientId ? bundle : null;
}

void main() {
  testWidgets('caregiver finds a pharmacy within 10 km and submits an order', (
    tester,
  ) async {
    Uri? pharmacyRequest;
    Map<String, dynamic>? orderRequest;
    final pharmacyResponse = jsonEncode([
      {
        'id': _pharmacyId,
        'pharmacistId': '507f1f77bcf86cd799439013',
        'name': 'Nhà thuốc An Tâm',
        'phoneNumber': '0901234567',
        'addressText': 'Quận 1, TP.HCM',
        'latitude': 10.78,
        'longitude': 106.70,
        'geohash': 'w3gvk1xyz',
        'distanceKm': 0.36,
      },
    ]);
    final pharmacyApi = PharmacyApi(
      client: MockClient((request) async {
        pharmacyRequest = request.url;
        return http.Response(
          pharmacyResponse,
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final orderApi = PharmacyOrderApi(
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response('[]', 200);
        }
        orderRequest = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': '22222222-2222-4222-8222-222222222222',
            'orderCode': 'MD12345678',
            'pharmacyId': _pharmacyId,
            'status': 'PENDING_REVIEW',
            'fulfillmentType': 'PICKUP',
            'totalAmount': 0,
            'createdAt': '2026-10-09T00:00:00.000Z',
            'items': const <Map<String, dynamic>>[],
          }),
          201,
        );
      }),
    );
    final controller = _TestCareNetworkController(
      const PatientBundle(
        detail: PatientDetail(
          id: _patientId,
          fullName: 'Nguyễn Văn A',
          email: 'patient@example.com',
          phone: '0900000000',
        ),
        schedules: [],
        prescriptions: [
          Prescription(
            id: _prescriptionId,
            patientId: _patientId,
            title: 'Đơn thuốc tháng 10',
            startDate: '2026-10-01',
            items: [
              PrescriptionItem(
                id: _prescriptionItemId,
                medicineName: 'Paracetamol',
                dosagePerTime: 1,
                currentStock: 1,
                reorderThreshold: 5,
                schedules: [],
              ),
            ],
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);
    addTearDown(pharmacyApi.close);
    addTearDown(orderApi.close);
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaregiverPharmacyScreen(
            controller: controller,
            pharmacyApi: pharmacyApi,
            orderApi: orderApi,
            locationProvider: const _FixedLocationProvider(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('find-nearby-pharmacies')));
    await tester.pumpAndSettle();

    expect(pharmacyRequest?.queryParameters['radiusKm'], '10.0');
    expect(
      pharmacyRequest?.queryParameters['geohash'],
      encodeGeohash(10.7769, 106.7009),
    );
    expect(find.text('Nhà thuốc An Tâm', skipOffstage: false), findsOneWidget);
    expect(find.text('0.36 km', skipOffstage: false), findsOneWidget);

    final orderButton = find.byKey(
      const Key('order-from-$_pharmacyId'),
      skipOffstage: false,
    );
    await tester.ensureVisible(orderButton);
    await tester.tap(orderButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('order-item-$_prescriptionItemId')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('submit-pharmacy-order')));
    await tester.tap(find.byKey(const Key('submit-pharmacy-order')));
    await tester.pumpAndSettle();

    expect(orderRequest?['caregiverId'], isNull);
    expect(orderRequest?['patientId'], _patientId);
    expect(orderRequest?['pharmacyId'], _pharmacyId);
    expect(orderRequest?['prescriptionId'], _prescriptionId);
    expect((orderRequest?['items'] as List).single, {
      'prescriptionItemId': _prescriptionItemId,
      'quantity': 5,
    });
    expect(
      find.byKey(
        const Key('caregiver-order-22222222-2222-4222-8222-222222222222'),
      ),
      findsOneWidget,
    );
  });
}
