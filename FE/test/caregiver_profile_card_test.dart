import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/billing_api.dart';
import 'package:meds_reminder/widgets/caregiver_profile_card.dart';

void main() {
  group('CaregiverProfileCard tests', () {
    testWidgets('renders profile for standard user and calls GET /api/v1/users/profile', (tester) async {
      var profileEndpointHit = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/users/profile') {
          profileEndpointHit = true;
          return http.Response(
            jsonEncode({
              'isPremium': false,
              'premiumExpiresAt': null,
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final billingApi = BillingApi(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaregiverProfileCard(
              userName: 'Nguyen Van A',
              userEmail: 'caregiver@example.com',
              billingApi: billingApi,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(profileEndpointHit, isTrue);
      expect(find.text('Nguyen Van A'), findsOneWidget);
      expect(find.text('caregiver@example.com'), findsOneWidget);
      expect(find.text('Người chăm sóc'), findsOneWidget);
      expect(find.text('Tiêu chuẩn'), findsOneWidget);
    });

    testWidgets('renders VIP badge and expiration date when isPremium is true', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/users/profile') {
          return http.Response(
            jsonEncode({
              'isPremium': true,
              'premiumExpiresAt': '2026-12-31T23:59:59.000Z',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final billingApi = BillingApi(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaregiverProfileCard(
              userName: 'Tran Thi B',
              userEmail: 'vip_caregiver@example.com',
              billingApi: billingApi,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tran Thi B'), findsOneWidget);
      expect(find.text('VIP'), findsAtLeastNWidgets(1));
      expect(find.text('VIP • Hết hạn 31/12/2026'), findsOneWidget);
    });
  });
}
