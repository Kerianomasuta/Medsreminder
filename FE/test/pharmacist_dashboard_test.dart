import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/controllers/pharmacist_dashboard_controller.dart';
import 'package:meds_reminder/models/models.dart';
import 'package:meds_reminder/screens/pharmacist/pharmacist_dashboard.dart';
import 'package:meds_reminder/services/pharmacy_api.dart';
import 'package:meds_reminder/services/pharmacy_order_api.dart';

void main() {
  testWidgets(
    'PharmacistDashboard renders 6 tabs, displays order cards, and handles tab switching',
    (tester) async {
      final requestedStatuses = <String?>[];

      final controller = PharmacistDashboardController(
        user: const AuthUser(
          id: '507f1f77bcf86cd799439013',
          email: 'pharmacist@example.com',
          fullName: 'Dược sĩ',
          role: AppRole.pharmacist,
        ),
        pharmacyApi: PharmacyApi(
          client: MockClient((_) async => http.Response('null', 200)),
        ),
        orderApi: PharmacyOrderApi(
          client: MockClient((request) async {
            requestedStatuses.add(request.url.queryParameters['status']);
            final status = request.url.queryParameters['status'];
            if (status == 'PREPARING') {
              return http.Response('[]', 200); // Empty list
            }
            final body = jsonEncode([
              {
                'id': 'ord-101',
                'orderCode': '#MR-001',
                'pharmacyId': 'ph-1',
                'status': status ?? 'PENDING_REVIEW',
                'fulfillmentType': 'PICKUP',
                'totalAmount': 120000,
                'createdAt': '2026-10-11T08:30:00.000Z',
                'items': [
                  {
                    'id': 'item-1',
                    'name': 'Paracetamol 500mg',
                    'unit': 'hop',
                    'quantity': 2,
                  }
                ],
              }
            ]);
            return http.Response.bytes(
              utf8.encode(body),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PharmacistDashboard(controller: controller),
          ),
        ),
      );

      // Verify all 6 tabs exist
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('Đang chuẩn bị'), findsOneWidget);
      expect(find.text('Chờ nhận/Giao'), findsOneWidget);
      expect(find.text('Hoàn tất'), findsOneWidget);
      expect(find.text('Đã hủy'), findsOneWidget);

      await tester.pumpAndSettle();


      // Verify OrderCard contents
      expect(find.text('#MR-001'), findsOneWidget);
      expect(find.text('Chờ duyệt'), findsWidgets);
      expect(find.textContaining('Thời gian đặt:'), findsOneWidget);
      expect(find.text('Xem chi tiết'), findsOneWidget);

      // Tap on Tab "Đang chuẩn bị" (empty state)
      await tester.tap(find.text('Đang chuẩn bị'));
      await tester.pumpAndSettle();

      expect(requestedStatuses.contains('PREPARING'), isTrue);
      expect(
        find.text('Không có đơn hàng nào ở trạng thái này'),
        findsOneWidget,
      );

      // Tap on Tab "Chờ duyệt"
      await tester.tap(find.text('Chờ duyệt'));
      await tester.pumpAndSettle();

      expect(requestedStatuses.contains('PENDING_REVIEW'), isTrue);
      expect(find.text('#MR-001'), findsOneWidget);

      // Tap "Xem chi tiết" to open bottom sheet
      await tester.tap(find.text('Xem chi tiết'));
      await tester.pumpAndSettle();
      expect(find.text('Đơn hàng #MR-001'), findsOneWidget);
      expect(find.text('Paracetamol 500mg'), findsOneWidget);

      controller.dispose();
    },
  );
}
