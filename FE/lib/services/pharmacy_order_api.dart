import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pharmacist_dashboard.dart';
import 'api_base_url.dart';
import 'http_client_factory.dart';

class PharmacyOrderApiException implements Exception {
  const PharmacyOrderApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PharmacyOrderApi {
  PharmacyOrderApi({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<List<PharmacyOrder>> listMine({PharmacyOrderStatus? status}) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/orders/mine').replace(
      queryParameters: status == null ? null : {'status': status.apiValue},
    );
    final payload = await _request('GET', uri);
    return (payload as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PharmacyOrder.fromJson)
        .toList(growable: false);
  }

  Future<PharmacyOrder> getById(String id) =>
      _order('GET', '/api/v1/orders/${Uri.encodeComponent(id)}');

  Future<PharmacyOrder> accept(String id) =>
      _order('POST', '/api/v1/orders/${Uri.encodeComponent(id)}/accept');

  Future<PharmacyOrder> reject(String id, String reason) => _order(
    'POST',
    '/api/v1/orders/${Uri.encodeComponent(id)}/reject',
    body: {'rejectionReason': reason.trim()},
  );

  Future<PharmacyOrder> markReady(String id) =>
      _order('POST', '/api/v1/orders/${Uri.encodeComponent(id)}/ready');

  Future<PharmacyOrder> ship(
    String id, {
    required String shipperName,
    required String shipperPhone,
  }) => _order(
    'POST',
    '/api/v1/orders/${Uri.encodeComponent(id)}/ship',
    body: {
      'shipperName': shipperName.trim(),
      'shipperPhone': shipperPhone.trim(),
    },
  );

  Future<PharmacyOrder> cancel(String id, String reason) => _order(
    'POST',
    '/api/v1/orders/${Uri.encodeComponent(id)}/cancel',
    body: {'rejectionReason': reason.trim()},
  );

  Future<PharmacyOrder> _order(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final payload = await _request(
      method,
      Uri.parse('$apiBaseUrl$path'),
      body: body,
    );
    if (payload is! Map<String, dynamic>) {
      throw const PharmacyOrderApiException('Phản hồi đơn hàng không hợp lệ.');
    }
    return PharmacyOrder.fromJson(payload);
  }

  Future<dynamic> _request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    late http.Response response;
    try {
      response = switch (method) {
        'GET' => await _client.get(uri),
        'POST' => await _client.post(
          uri,
          headers: body == null
              ? null
              : const {'Content-Type': 'application/json; charset=utf-8'},
          body: body == null ? null : jsonEncode(body),
        ),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      };
    } catch (error) {
      if (error is PharmacyOrderApiException) rethrow;
      throw const PharmacyOrderApiException(
        'Không thể kết nối dịch vụ đơn hàng. Vui lòng thử lại.',
      );
    }

    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw PharmacyOrderApiException(
        message ?? 'Yêu cầu thất bại (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  void close() => _client.close();
}
