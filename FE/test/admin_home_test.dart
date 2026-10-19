import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/screens/admin/admin_home.dart';
import 'package:meds_reminder/services/admin_api.dart';

void main() {
  group('AdminHome widget tests', () {
    testWidgets('renders Tab 0 Overview with 4 stat cards and summaries', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/admin/summary') {
          return http.Response(
            jsonEncode({
              'users': {
                'total': 120,
                'patient': 70,
                'caregiver': 30,
                'pharmacist': 15,
                'admin': 5,
                'premium': 25,
                'inactive': 3,
                'registeredLast7Days': 14,
              },
              'links': {'active': 28, 'inactive': 2},
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/admin/payments/summary') {
          return http.Response(
            jsonEncode({
              'total': {'count': 10, 'amount': 490000},
              'paidLast7Days': {'count': 3, 'amount': 147000},
              'paidLast30Days': {'count': 8, 'amount': 392000},
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/admin/pharmacy/summary') {
          return http.Response(
            jsonEncode({
              'pharmacies': {'total': 8, 'createdLast7Days': 2},
              'orders': {
                'total': 45,
                'createdLast7Days': 12,
                'completedAmount': 0,
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/admin/medication/summary') {
          return http.Response(
            jsonEncode({
              'prescriptions': {
                'total': 60,
                'active': 38,
                'inactive': 22,
                'createdLast7Days': 9,
              },
              'items': {'total': 180, 'lowStock': 4},
              'schedules': {'total': 50, 'active': 35},
              'logs': {'total': 210, 'createdLast7Days': 40},
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final adminApi = AdminApi(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdminHome(tab: 0, adminApi: adminApi)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tổng doanh thu'), findsOneWidget);
      expect(find.text('Người dùng mới'), findsOneWidget);
      expect(find.text('+14'), findsOneWidget);
      expect(find.text('Đơn thuốc đang dùng'), findsOneWidget);
      expect(find.text('38'), findsOneWidget);
      expect(find.text('Nhà thuốc hoạt động'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets(
      'renders Tab 1 Users with search, filter chips, and user list',
      (tester) async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/v1/admin/users') {
            return http.Response(
              jsonEncode({
                'page': 1,
                'limit': 20,
                'total': 1,
                'users': [
                  {
                    'id': '6abbd74f1a65898500954ec6',
                    'email': 'memaybeo@gmail.com',
                    'fullName': 'Nguyen Van A',
                    'role': 'PATIENT',
                    'isPremium': true,
                    'isActive': true,
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        });

        final adminApi = AdminApi(client: mockClient);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AdminHome(tab: 1, adminApi: adminApi)),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Nguyen Van A'), findsOneWidget);
        expect(find.text('memaybeo@gmail.com'), findsOneWidget);
        expect(find.text('VIP'), findsOneWidget);
        expect(find.text('Hoạt động'), findsOneWidget);
      },
    );
  });
}
