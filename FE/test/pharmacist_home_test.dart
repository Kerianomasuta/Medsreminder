import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/controllers/pharmacist_dashboard_controller.dart';
import 'package:meds_reminder/models/models.dart';
import 'package:meds_reminder/screens/pharmacist/pharmacist_home.dart';
import 'package:meds_reminder/services/pharmacy_order_api.dart';

void main() {
  testWidgets('pharmacist home only renders order screens', (tester) async {
    final controller = PharmacistDashboardController(
      user: const AuthUser(
        id: '507f1f77bcf86cd799439013',
        email: 'pharmacist@example.com',
        fullName: 'Dược sĩ',
        role: AppRole.pharmacist,
      ),
      orderApi: PharmacyOrderApi(
        client: MockClient((_) async => http.Response('[]', 200)),
      ),
    );
    await controller.initialize();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PharmacistHome(tab: 0, controller: controller)),
      ),
    );
    expect(find.text('Xử lý đơn thuốc'), findsOneWidget);
    expect(find.text('Nhà thuốc của tôi'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PharmacistHome(tab: 1, controller: controller)),
      ),
    );
    expect(find.text('Lịch sử đơn thuốc'), findsOneWidget);
    expect(find.text('Nhà thuốc của tôi'), findsNothing);
  });
}
