import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/session_refreshing_client.dart';

void main() {
  final refreshUri = Uri.parse(
    'http://localhost:5000/api/v1/auth/refreshToken',
  );

  test(
    'refreshes an expired session and retries the original request',
    () async {
      var authenticated = false;
      final calls = <String>[];
      final client = SessionRefreshingClient(
        MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.url == refreshUri) {
            authenticated = true;
            return http.Response('{}', 200);
          }
          return authenticated
              ? http.Response(jsonEncode({'data': <dynamic>[]}), 200)
              : http.Response('Token is missing from cookies!', 401);
        }),
        refreshUri: refreshUri,
      );

      final response = await client.get(
        Uri.parse('http://localhost:5000/api/v1/orders/mine'),
      );

      expect(response.statusCode, 200);
      expect(calls, [
        'GET /api/v1/orders/mine',
        'POST /api/v1/auth/refreshToken',
        'GET /api/v1/orders/mine',
      ]);
    },
  );

  test('preserves a JSON request body when retrying', () async {
    var authenticated = false;
    final receivedBodies = <String>[];
    final client = SessionRefreshingClient(
      MockClient((request) async {
        if (request.url == refreshUri) {
          authenticated = true;
          return http.Response('{}', 200);
        }
        receivedBodies.add(request.body);
        return http.Response('{}', authenticated ? 200 : 401);
      }),
      refreshUri: refreshUri,
    );

    final response = await client.post(
      Uri.parse('http://localhost:5000/api/v1/orders'),
      headers: {'Content-Type': 'application/json'},
      body: '{"pharmacyId":"abc"}',
    );

    expect(response.statusCode, 200);
    expect(receivedBodies, ['{"pharmacyId":"abc"}', '{"pharmacyId":"abc"}']);
  });

  test('does not recursively refresh a rejected auth request', () async {
    var calls = 0;
    final client = SessionRefreshingClient(
      MockClient((_) async {
        calls += 1;
        return http.Response('Unauthorized', 401);
      }),
      refreshUri: refreshUri,
    );

    final response = await client.post(refreshUri, body: '{}');

    expect(response.statusCode, 401);
    expect(calls, 1);
  });
}
