import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/admin_api.dart';

void main() {
  group('AdminApi tests', () {
    test(
      'getSummary calls /api/v1/admin/summary and returns AdminSummary',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/api/v1/admin/summary');
          return http.Response(
            jsonEncode({
              'users': {
                'total': 150,
                'patient': 80,
                'caregiver': 40,
                'pharmacist': 20,
                'admin': 10,
                'premium': 35,
                'inactive': 5,
                'registeredLast7Days': 18,
              },
              'links': {'active': 30, 'inactive': 2},
            }),
            200,
          );
        });

        final api = AdminApi(client: mockClient);
        final res = await api.getSummary();

        expect(res.totalUsers, 150);
        expect(res.patientCount, 80);
        expect(res.caregiverCount, 40);
        expect(res.registeredLast7Days, 18);
      },
    );

    test('getPaymentsSummary calls /api/v1/admin/payments/summary', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/admin/payments/summary');
        return http.Response(
          jsonEncode({
            'total': {'count': 12, 'amount': 588000},
            'paidLast7Days': {'count': 4, 'amount': 196000},
            'paidLast30Days': {'count': 10, 'amount': 490000},
          }),
          200,
        );
      });

      final api = AdminApi(client: mockClient);
      final res = await api.getPaymentsSummary();

      expect(res.totalAmount, 588000.0);
      expect(res.paidLast7DaysAmount, 196000.0);
    });

    test(
      'getPaymentsSummary parses flat number total and paidAmount correctly',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'total': 6,
              'pending': 0,
              'paid': 6,
              'failed': 0,
              'paidAmount': 600000,
              'pendingAmount': 0,
              'month': {'paid': 6, 'paidAmount': 600000},
              'year': {'paid': 0, 'paidAmount': 0},
              'paidLast7Days': {'count': 2, 'amount': 200000},
              'paidLast30Days': {'count': 6, 'amount': 600000},
            }),
            200,
          );
        });

        final api = AdminApi(client: mockClient);
        final res = await api.getPaymentsSummary();

        expect(res.totalCount, 6);
        expect(res.totalAmount, 600000.0);
        expect(res.paidLast7DaysCount, 2);
        expect(res.paidLast7DaysAmount, 200000.0);
      },
    );

    test(
      'searchPrescriptions sends all filters and parses full rows',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/api/v1/admin/prescriptions');
          expect(
            request.url.queryParameters['patientId'],
            '6abbd74f1a65898500954ec6',
          );
          expect(request.url.queryParameters['isActive'], 'true');
          expect(request.url.queryParameters['q'], 'ARS-1886');
          return http.Response(
            jsonEncode({
              'page': 1,
              'limit': 20,
              'total': 1,
              'prescriptions': [
                {'id': 'p1', 'prescriptionCode': 'ARS-1886', 'isActive': true},
              ],
            }),
            200,
          );
        });

        final result = await AdminApi(client: mockClient).searchPrescriptions(
          patientId: '6abbd74f1a65898500954ec6',
          isActive: true,
          q: 'ARS-1886',
        );
        expect(result.total, 1);
        expect(result.items.single['prescriptionCode'], 'ARS-1886');
      },
    );

    test('getOrderDetail calls the admin order detail endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.path,
          '/api/v1/admin/orders/3ad3b1e8-3405-472f-85c4-5298b6ce7443',
        );
        return http.Response(
          jsonEncode({
            'order': {'id': 'o1', 'status': 'CANCELLED'},
            'items': [
              {'id': 'i1', 'name': 'Paracetamol', 'quantity': 2},
            ],
          }),
          200,
        );
      });

      final result = await AdminApi(client: mockClient)
          .getOrderDetail('3ad3b1e8-3405-472f-85c4-5298b6ce7443');
      expect(result['order']['status'], 'CANCELLED');
      expect((result['items'] as List).single['quantity'], 2);
    });

    test('getUsers calls /api/v1/admin/users with query params', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/admin/users');
        expect(request.url.queryParameters['role'], 'PATIENT');
        expect(request.url.queryParameters['q'], 'memaybeo@gmail.com');
        expect(request.url.queryParameters['isActive'], 'true');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['limit'], '20');

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
                'isPremium': false,
                'isActive': true,
              },
            ],
          }),
          200,
        );
      });

      final api = AdminApi(client: mockClient);
      final res = await api.getUsers(
        role: 'PATIENT',
        q: 'memaybeo@gmail.com',
        isActive: true,
        page: 1,
        limit: 20,
      );

      expect(res.total, 1);
      expect(res.users.first.email, 'memaybeo@gmail.com');
    });

    test('getUserDetail calls /api/v1/admin/users/{userId}', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.path,
          '/api/v1/admin/users/6abbd74f1a65898500954ec6',
        );
        return http.Response(
          jsonEncode({
            'user': {
              'id': '6abbd74f1a65898500954ec6',
              'email': 'memaybeo@gmail.com',
              'fullName': 'Nguyen Van A',
              'role': 'PATIENT',
              'isPremium': true,
              'isActive': true,
            },
            'links': [],
          }),
          200,
        );
      });

      final api = AdminApi(client: mockClient);
      final res = await api.getUserDetail('6abbd74f1a65898500954ec6');

      expect(res.user.id, '6abbd74f1a65898500954ec6');
      expect(res.user.fullName, 'Nguyen Van A');
      expect(res.user.isPremium, isTrue);
    });

    test('updateUser calls PATCH /api/v1/admin/users/{userId}', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.path,
          '/api/v1/admin/users/6ac0c8912474b8578a772a3e',
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['fullName'], 'Nguyen Van B');
        expect(body['isActive'], false);

        return http.Response(
          jsonEncode({
            'id': '6ac0c8912474b8578a772a3e',
            'fullName': 'Nguyen Van B',
            'email': 'b@example.com',
            'role': 'CARE_GIVER',
            'isActive': false,
            'isPremium': false,
          }),
          200,
        );
      });

      final api = AdminApi(client: mockClient);
      final res = await api.updateUser(
        '6ac0c8912474b8578a772a3e',
        fullName: 'Nguyen Van B',
        isActive: false,
      );

      expect(res.fullName, 'Nguyen Van B');
      expect(res.isActive, isFalse);
    });
  });
}
