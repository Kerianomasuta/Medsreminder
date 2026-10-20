import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/billing_api.dart';

void main() {
  group('BillingApi tests', () {
    test('getConfig returns isPaymentEnabled: true', () async {
      final api = BillingApi(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/billing/config');
          return http.Response(
            jsonEncode({'is_payment_enabled': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final config = await api.getConfig();
      expect(config.isPaymentEnabled, isTrue);
    });

    test('getPlans returns MONTH and YEAR plans', () async {
      final api = BillingApi(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/billing/plans');
          return http.Response(
            jsonEncode({
              'plans': [
                {'plan': 'MONTH', 'amount': 49000, 'label': '1 tháng'},
                {'plan': 'YEAR', 'amount': 470400, 'label': '1 năm, giảm 20%'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final plans = await api.getPlans();
      expect(plans.length, 2);
      expect(plans.first.plan, 'MONTH');
      expect(plans.first.amount, 49000);
      expect(plans.last.plan, 'YEAR');
      expect(plans.last.amount, 470400);
    });

    test('createPaymentLink creates PayOS checkout link with plan MONTH', () async {
      late http.Request sentRequest;
      final api = BillingApi(
        client: MockClient((request) async {
          sentRequest = request;
          expect(request.url.path, '/api/v1/billing/create-payment-link');
          return http.Response(
            jsonEncode({
              'checkoutUrl': 'https://pay.payos.vn/web/123456',
              'orderCode': 99999,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await api.createPaymentLink('MONTH');
      expect(result.checkoutUrl, 'https://pay.payos.vn/web/123456');
      expect(result.orderCode, 99999);
      expect(jsonDecode(sentRequest.body), {'plan': 'MONTH'});
    });

    test('confirmPayosWebhook triggers PayOS webhook', () async {
      late http.Request sentRequest;
      final api = BillingApi(
        client: MockClient((request) async {
          sentRequest = request;
          expect(request.url.path, '/api/v1/billing/payos-webhook');
          return http.Response(
            jsonEncode({'success': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final payload = {
        'code': '00',
        'desc': 'success',
        'success': true,
        'data': {'orderCode': 99999, 'amount': 49000},
      };

      final response = await api.confirmPayosWebhook(payload);
      expect(response['success'], isTrue);
      expect(jsonDecode(sentRequest.body), payload);
    });

    test('getUserVipProfile returns isPremium and expiry', () async {
      final api = BillingApi(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/users/profile');
          return http.Response(
            jsonEncode({
              'isPremium': true,
              'premiumExpiresAt': '2026-11-16T10:00:00.000Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final profile = await api.getUserVipProfile();
      expect(profile.isPremium, isTrue);
      expect(profile.premiumExpiresAt, isNotNull);
      expect(profile.premiumExpiresAt?.year, 2026);
      expect(profile.premiumExpiresAt?.month, 11);
    });
  });
}
