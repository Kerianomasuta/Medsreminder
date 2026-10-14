import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/registration_input.dart';
import 'api_base_url.dart';
import 'auth_cookie_adapter.dart';
import 'http_client_factory.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({http.Client? client})
    : _client = client ?? createHttpClient(),
      _cookies = AuthCookieAdapter();

  final http.Client _client;
  final AuthCookieAdapter _cookies;

  Future<AuthUser> login({required String email, required String password}) =>
      _authenticate('/api/v1/auth/login', {
        'email': email,
        'password': password,
      }, email: email);

  Future<AuthUser> refreshSession() =>
      _authenticate('/api/v1/auth/refreshToken', const {});

  Future<void> register(RegistrationInput input) async {
    await _post('/api/v1/auth/register', input.toJson());
  }

  Future<void> logout() async {
    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/api/v1/auth/logout'),
      headers: _cookies.requestHeaders,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_messageFrom(response));
    }
    _cookies.clear();
  }

  Future<AuthUser> _authenticate(
    String path,
    Map<String, Object> body, {
    String email = '',
  }) async {
    final response = await _post(path, body);
    final responseUser = _userFrom(response, fallbackEmail: email);
    if (responseUser != null) return responseUser;

    final token = _cookies.accessToken;
    if (token == null) {
      throw const AuthApiException(
        'Máy chủ không trả về thông tin phiên đăng nhập.',
      );
    }

    try {
      final claims = _decodeJwtPayload(token);
      return AuthUser.fromJson({
        'id': claims['userId'],
        'email': email,
        'fullName': claims['fullName'],
        'role': claims['role'],
      });
    } catch (_) {
      throw const AuthApiException('Access token không hợp lệ.');
    }
  }

  AuthUser? _userFrom(http.Response response, {required String fallbackEmail}) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'];
      if (data is! Map<String, dynamic>) return null;

      final rawUser = data['user'] ?? data['userWithoutPassword'];
      if (rawUser is! Map<String, dynamic>) return null;

      return AuthUser.fromJson({
        ...rawUser,
        'id': rawUser['id'] ?? rawUser['_id'],
        'email': rawUser['email']?.toString().isNotEmpty == true
            ? rawUser['email']
            : fallbackEmail,
      });
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> _post(String path, Map<String, Object> body) async {
    late http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$apiBaseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          ..._cookies.requestHeaders,
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const AuthApiException(
        'Không thể kết nối máy chủ. Hãy kiểm tra kết nối mạng và thử lại.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_messageFrom(response));
    }
    _cookies.capture(response.headers);
    return response;
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('Invalid JWT');
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    return jsonDecode(payload) as Map<String, dynamic>;
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
