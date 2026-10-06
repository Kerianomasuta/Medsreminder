import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/models/app_role.dart';
import 'package:meds_reminder/services/auth_api.dart';

void main() {
  test('login reads the role from the access token cookie', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({'status': 'success'}),
        200,
        headers: {
          'set-cookie': 'accessToken=${_token(role: 'PHARMACIST')}; HttpOnly',
        },
      ),
    );

    final user = await AuthApi(client: client)
        .login(email: 'pharmacist@example.com', password: 'password123');

    expect(user.role, AppRole.pharmacist);
    expect(user.fullName, 'Dược sĩ Demo');
  });

  test('register calls the backend with its expected role value', () async {
    Map<String, dynamic>? sentBody;
    final client = MockClient((request) async {
      sentBody = jsonDecode(request.body) as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/auth/register');
      return http.Response(jsonEncode({'status': 201}), 201);
    });

    await AuthApi(client: client).register(
      email: 'caregiver@example.com',
      password: 'password123',
      fullName: 'Người chăm sóc',
      phone: '0912345678',
      role: AppRole.caregiver,
    );

    expect(sentBody?['role'], 'CARE_GIVER');
  });
}

String _token({required String role}) {
  String part(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'userId': 'pharmacist-1', 'fullName': 'Dược sĩ Demo', 'role': role})}.signature';
}
