import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/controllers/pharmacist_dashboard_controller.dart';
import 'package:meds_reminder/models/models.dart';
import 'package:meds_reminder/screens/app_shell.dart';
import 'package:meds_reminder/services/pharmacy_api.dart';
import 'package:meds_reminder/services/pharmacy_order_api.dart';

void main() {
  testWidgets('pharmacist information shows account and pharmacy details', (
    tester,
  ) async {
    Uri? requestedUri;
    final controller = PharmacistDashboardController(
      user: const AuthUser(
        id: '507f1f77bcf86cd799439013',
        email: 'duocsi@example.com',
        fullName: 'Nguyễn Văn Dược',
        role: AppRole.pharmacist,
      ),
      orderApi: PharmacyOrderApi(
        client: MockClient((_) async => http.Response('[]', 200)),
      ),
      pharmacyApi: PharmacyApi(
        client: MockClient((request) async {
          requestedUri = request.url;
          final pharmacy = {
            'id': '11111111-1111-4111-8111-111111111111',
            'pharmacistId': '507f1f77bcf86cd799439013',
            'name': 'Nhà thuốc An Tâm',
            'phoneNumber': '0901234567',
            'addressText': '123 Nguyễn Huệ, Quận 1, TP.HCM',
            'latitude': 10.7769,
            'longitude': 106.7009,
            'geohash': 'w3gvk1xyz',
          };
          return http.Response(
            jsonEncode(
              request.url.path == '/api/v1/pharmacies' ? [pharmacy] : pharmacy,
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopBar(
            role: AppRole.pharmacist,
            userName: 'Nguyễn Văn Dược',
            userEmail: 'duocsi@example.com',
            pharmacistController: controller,
            onLogout: () async {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('account-information-button')));
    await tester.pumpAndSettle();

    expect(
      requestedUri?.path,
      '/api/v1/pharmacies/11111111-1111-4111-8111-111111111111',
    );
    expect(
      find.byKey(const Key('pharmacist-account-information')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pharmacist-pharmacy-information')),
      findsOneWidget,
    );
    expect(find.text('Nguyễn Văn Dược'), findsNWidgets(2));
    expect(find.text('duocsi@example.com'), findsOneWidget);
    expect(find.text('Nhà thuốc An Tâm'), findsOneWidget);
    expect(find.text('0901234567'), findsOneWidget);
    expect(find.text('123 Nguyễn Huệ, Quận 1, TP.HCM'), findsOneWidget);
    expect(find.text('10.776900, 106.700900'), findsOneWidget);
    expect(find.text('w3gvk1xyz'), findsOneWidget);
  });
}
