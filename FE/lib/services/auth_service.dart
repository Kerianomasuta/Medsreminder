import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_role.dart';

class AuthUser {
  final String userId;
  final String deviceId;
  final String fullName;
  final String rawRole;
  final AppRole role;
  final String? accessToken;
  final String? refreshToken;

  const AuthUser({
    required this.userId,
    required this.deviceId,
    required this.fullName,
    required this.rawRole,
    required this.role,
    this.accessToken,
    this.refreshToken,
  });

  factory AuthUser.fromJwtPayload(
    Map<String, dynamic> payload, {
    String? accessToken,
    String? refreshToken,
  }) {
    final rawRole = payload['role'] as String? ?? 'PATIENT';
    return AuthUser(
      userId: payload['userId'] as String? ?? '',
      deviceId: payload['deviceId'] as String? ?? '',
      fullName: payload['fullName'] as String? ?? 'Người dùng',
      rawRole: rawRole,
      role: _mapRole(rawRole),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static AppRole _mapRole(String raw) {
    switch (raw.toUpperCase()) {
      case 'CARE_GIVER':
      case 'CAREGIVER':
        return AppRole.caregiver;
      case 'PHARMACIST':
        return AppRole.pharmacist;
      case 'DRUGSHIPPER':
      case 'SHIPPER':
        return AppRole.shipper;
      case 'ADMIN':
        return AppRole.admin;
      case 'PATIENT':
      default:
        return AppRole.patient;
    }
  }
}

class LoginResult {
  final bool isSuccess;
  final String message;
  final AuthUser? user;

  const LoginResult({
    required this.isSuccess,
    required this.message,
    this.user,
  });
}

class AuthService {
  // Đối với web/desktop dùng localhost:3000, đối với Android emulator thường dùng 10.0.2.2:3000
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  static AuthUser? currentUser;

  /// Gọi API POST /api/v1/auth/login
  static Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 1. Đọc token từ response data (chuẩn cho Mobile/Web)
        final responseData = data['data'] as Map<String, dynamic>?;
        String? accessToken = responseData?['accessToken'] as String?;
        String? refreshToken = responseData?['refreshToken'] as String?;

        // 2. Dự phòng: Trích xuất từ Set-Cookie headers nếu có
        if (accessToken == null || accessToken.isEmpty) {
          final setCookie = response.headers['set-cookie'] ?? '';
          accessToken = _extractCookieValue(setCookie, 'accessToken');
          refreshToken = _extractCookieValue(setCookie, 'refreshToken');
        }

        if (accessToken != null && accessToken.isNotEmpty) {
          final payload = _decodeJwt(accessToken);
          currentUser = AuthUser.fromJwtPayload(
            payload,
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

          return LoginResult(
            isSuccess: true,
            message: data['message'] ?? 'Đăng nhập thành công!',
            user: currentUser,
          );
        }

        return LoginResult(
          isSuccess: true,
          message: data['message'] ?? 'Đăng nhập thành công!',
          user: const AuthUser(
            userId: '',
            deviceId: '',
            fullName: 'Người dùng',
            rawRole: 'PATIENT',
            role: AppRole.patient,
          ),
        );
      } else {
        final message = data['message'] is List
            ? (data['message'] as List).join(', ')
            : data['message'] ?? 'Đăng nhập thất bại (${response.statusCode})';
        return LoginResult(isSuccess: false, message: message);
      }
    } catch (e) {
      return LoginResult(
        isSuccess: false,
        message: 'Lỗi kết nối máy chủ: $e',
      );
    }
  }

  /// Trích xuất cookie theo tên
  static String? _extractCookieValue(String setCookieHeader, String key) {
    if (setCookieHeader.isEmpty) return null;
    final regex = RegExp('$key=([^;]+)');
    final match = regex.firstMatch(setCookieHeader);
    return match?.group(1);
  }

  /// Giải mã payload JWT base64
  static Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payloadString) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
