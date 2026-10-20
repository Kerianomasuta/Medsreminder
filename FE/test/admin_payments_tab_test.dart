import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/screens/admin/admin_payments_tab.dart';
import 'package:meds_reminder/services/admin_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  http.Response jsonUtf8(dynamic body, int statusCode) {
    return http.Response(
      jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  group('AdminPaymentsTab tests', () {
    testWidgets('searches payments by email kkk@gmail.com and renders without console error',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/admin/payments/summary') {
          return jsonUtf8({
            'total': 6,
            'paid': 2,
            'paidAmount': 98000,
            'pending': 4,
            'pendingAmount': 1038800,
            'failed': 0,
            'failedAmount': 0,
            'month': {'paid': 2, 'paidAmount': 98000},
            'year': {'paid': 0, 'paidAmount': 0},
          }, 200);
        }

        if (request.url.path == '/api/v1/admin/users' &&
            request.url.queryParameters['q'] == 'kkk@gmail.com') {
          return jsonUtf8({
            'page': 1,
            'limit': 10,
            'total': 1,
            'users': [
              {
                'id': '6abbd74f1a65898500954ec6',
                'fullName': 'Kien khoai khung',
                'email': 'kkk@gmail.com',
                'phone': '0912345678',
                'role': 'PATIENT',
                'isActive': true,
              }
            ],
          }, 200);
        }

        if (request.url.path == '/api/v1/admin/payments') {
          final q = request.url.queryParameters['q'];
          if (q == '179212310012') {
            return jsonUtf8({
              'page': 1,
              'limit': 20,
              'total': 1,
              'payments': [
                {
                  'id': 'pay-2',
                  'userId': '6abbd74f1a65898500954ec6',
                  'user': {
                    'id': '6abbd74f1a65898500954ec6',
                    'fullName': 'Kien khoai khung',
                    'email': 'kkk@gmail.com',
                  },
                  'plan': 'MONTH',
                  'amount': 49000,
                  'txnRef': '179212310012',
                  'status': 'PAID',
                  'createdAt': '2026-10-16T08:00:00.000Z',
                }
              ],
            }, 200);
          }

          return jsonUtf8({
            'page': 1,
            'limit': 20,
            'total': 2,
            'payments': [
              {
                'id': 'pay-1',
                'userId': 'user-1',
                'user': {
                  'id': 'user-1',
                  'fullName': 'Quy chợ lớn',
                  'email': 'bakhi@gmail.com',
                },
                'plan': 'MONTH',
                'amount': 49000,
                'txnRef': '179215009200',
                'status': 'PENDING',
                'createdAt': '2026-10-15T08:00:00.000Z',
              },
              {
                'id': 'pay-2',
                'userId': '6abbd74f1a65898500954ec6',
                'user': {
                  'id': '6abbd74f1a65898500954ec6',
                  'fullName': 'Kien khoai khung',
                  'email': 'kkk@gmail.com',
                },
                'plan': 'MONTH',
                'amount': 49000,
                'txnRef': '179212310012',
                'status': 'PAID',
                'createdAt': '2026-10-16T08:00:00.000Z',
              }
            ],
          }, 200);
        }

        return jsonUtf8({}, 404);
      });

      final adminApi = AdminApi(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPaymentsTab(adminApi: adminApi),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Initial cards
      expect(find.text('Doanh thu thực tế'), findsOneWidget);
      expect(find.text('Quy chợ lớn'), findsOneWidget);
      expect(find.text('Kien khoai khung'), findsOneWidget);

      // Enter search by txnRef: 179212310012
      await tester.enterText(
          find.widgetWithText(
              TextField, 'Tìm theo mã txnRef, mã giao dịch cổng...'),
          '179212310012');
      await tester.pumpAndSettle();

      // Tap search button
      await tester.tap(find.text('Tìm'));
      await tester.pumpAndSettle();

      // Verify that the matching transaction is found and displayed
      expect(find.text('Kien khoai khung'), findsOneWidget);
      expect(find.text('Quy chợ lớn'), findsNothing);
    });
  });
}
