import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_base_url.dart';
import 'http_client_factory.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<void> login({required String email, required String password}) =>
      _post('/api/v1/auth/login', {'email': email, 'password': password});

  Future<void> refreshSession() => _post('/api/v1/auth/refreshToken', const {});

  Future<void> logout() async {
    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/api/v1/auth/logout'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_messageFrom(response));
    }
  }

  Future<void> _post(String path, Map<String, Object> body) async {
    late http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$apiBaseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const AuthApiException(
        'Không thể kết nối máy chủ. Hãy kiểm tra Docker backend đang chạy.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_messageFrom(response));
    }
  }

  String _messageFrom(http.Response response) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final message = payload['message'];
      if (message is List) return message.join('\n');
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}
    return 'Yêu cầu thất bại (${response.statusCode}).';
  }

  void close() => _client.close();
}
