import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_base_url.dart';
import 'auth_cookie_adapter.dart';
import 'http_client_factory.dart';

class FcmTokenApiException implements Exception {
  const FcmTokenApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// PUT /api/v1/users/me/fcm-token — lưu FCM token của thiết bị đang đăng nhập.
class FcmTokenApi {
  FcmTokenApi({http.Client? client, AuthCookieAdapter? cookies})
    : _client = client ?? createHttpClient(),
      _cookies = cookies ?? AuthCookieAdapter();

  static const maxTokenLength = 4096;

  final http.Client _client;
  final AuthCookieAdapter _cookies;

  /// Trả về `false` (không gọi API) nếu token rỗng/null/quá dài.
  Future<bool> saveToken(String? token) async {
    final normalized = token?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        normalized.length > maxTokenLength) {
      return false;
    }
    final response = await _client.put(
      Uri.parse('$apiBaseUrl/api/v1/users/me/fcm-token'),
      headers: {
        ..._cookies.requestHeaders,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': normalized}),
    );
    if (response.statusCode != 200) throw _exception(response);
    return true;
  }

  FcmTokenApiException _exception(http.Response response) {
    final fallback = switch (response.statusCode) {
      400 => 'FCM token không hợp lệ.',
      401 => 'Phiên đăng nhập đã hết hạn.',
      _ => 'Không thể lưu FCM token (${response.statusCode}).',
    };
    var message = fallback;
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final value = payload['message'];
      if (value is String && value.isNotEmpty) message = value;
      if (value is List && value.isNotEmpty) message = value.join('\n');
    } catch (_) {}
    return FcmTokenApiException(message, statusCode: response.statusCode);
  }

  void close() => _client.close();
}
