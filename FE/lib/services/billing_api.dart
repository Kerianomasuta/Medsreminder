import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_base_url.dart';
import 'http_client_factory.dart';

class BillingConfig {
  const BillingConfig({required this.isPaymentEnabled});

  final bool isPaymentEnabled;

  factory BillingConfig.fromJson(Map<String, dynamic> json) => BillingConfig(
        isPaymentEnabled: json['is_payment_enabled'] == true ||
            json['isPaymentEnabled'] == true,
      );
}

class BillingPlan {
  const BillingPlan({
    required this.plan,
    required this.amount,
    required this.label,
  });

  final String plan;
  final int amount;
  final String label;

  factory BillingPlan.fromJson(Map<String, dynamic> json) => BillingPlan(
        plan: json['plan']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        label: json['label']?.toString() ?? '',
      );
}

class PaymentLinkResult {
  const PaymentLinkResult({
    required this.checkoutUrl,
    required this.orderCode,
  });

  final String checkoutUrl;
  final int orderCode;

  factory PaymentLinkResult.fromJson(Map<String, dynamic> json) =>
      PaymentLinkResult(
        checkoutUrl: json['checkoutUrl']?.toString() ?? '',
        orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
      );
}

class UserVipProfile {
  const UserVipProfile({
    required this.isPremium,
    this.premiumExpiresAt,
  });

  final bool isPremium;
  final DateTime? premiumExpiresAt;

  factory UserVipProfile.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['premiumExpiresAt'];
    DateTime? expiry;
    if (rawExpiry != null) {
      expiry = DateTime.tryParse(rawExpiry.toString());
    }
    return UserVipProfile(
      isPremium: json['isPremium'] == true || json['is_premium'] == true,
      premiumExpiresAt: expiry,
    );
  }
}

class BillingApi {
  BillingApi({http.Client? client}) : _client = client ?? createHttpClient();

  final http.Client _client;

  /// 1. GET /api/v1/billing/config
  Future<BillingConfig> getConfig() async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/v1/billing/config'),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return BillingConfig.fromJson(json);
    }
    throw Exception('Không lấy được cấu hình thanh toán (${response.statusCode})');
  }

  /// 2. GET /api/v1/billing/plans
  Future<List<BillingPlan>> getPlans() async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/v1/billing/plans'),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['plans'] as List<dynamic>? ?? const [];
      return list
          .map((item) => BillingPlan.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Không tải được danh sách gói cước (${response.statusCode})');
  }

  /// 3. POST /api/v1/billing/create-payment-link
  Future<PaymentLinkResult> createPaymentLink(
    String plan, {
    String? returnUrl,
    String? cancelUrl,
  }) async {
    final body = <String, Object>{'plan': plan};
    if (returnUrl != null && returnUrl.isNotEmpty) body['returnUrl'] = returnUrl;
    if (cancelUrl != null && cancelUrl.isNotEmpty) body['cancelUrl'] = cancelUrl;
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/v1/billing/create-payment-link'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaymentLinkResult.fromJson(json);
    }
    try {
      final json = jsonDecode(response.body);
      final message = json is Map ? json['message'] ?? response.body : response.body;
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi tạo link thanh toán (${response.statusCode}): ${response.body}');
    }
  }

  /// 4. POST /api/v1/billing/payos-webhook
  Future<Map<String, dynamic>> confirmPayosWebhook(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/v1/billing/payos-webhook'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'statusCode': response.statusCode, 'body': response.body};
    }
  }

  /// Lấy thông tin trạng thái VIP của người dùng: GET /api/v1/users/profile
  Future<UserVipProfile> getUserVipProfile() async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/v1/users/profile'),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserVipProfile.fromJson(json);
    }
    throw Exception('Không lấy được trạng thái VIP (${response.statusCode})');
  }
}

/// PayOS opens this page after payment or when the payer presses Cancel.
const paymentPageUrl = 'https://medsreminder.vercel.app/';

String paymentReturnUrl() => paymentPageUrl;

String paymentCancelUrl() => paymentPageUrl;
