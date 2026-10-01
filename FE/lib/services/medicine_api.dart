import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/medicine.dart';
import 'api_base_url.dart';
import 'http_client_factory.dart';

class MedicineApiException implements Exception {
  const MedicineApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MedicineApi {
  MedicineApi({http.Client? client}) : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<List<Medicine>> list({String? search}) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/medicines').replace(
      queryParameters: search == null || search.trim().isEmpty
          ? null
          : {'search': search.trim()},
    );
    final payload = await _request('GET', uri);
    return (payload as List<dynamic>)
        .map((item) => Medicine.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Medicine> getById(String id) async {
    final payload = await _request(
      'GET',
      Uri.parse('$apiBaseUrl/api/v1/medicines/$id'),
    );
    return Medicine.fromJson(payload as Map<String, dynamic>);
  }

  Future<Medicine> create(MedicineInput input) async {
    final payload = await _request(
      'POST',
      Uri.parse('$apiBaseUrl/api/v1/medicines'),
      body: input.toJson(),
    );
    return Medicine.fromJson(payload as Map<String, dynamic>);
  }

  Future<Medicine> update(String id, MedicineInput input) async {
    final payload = await _request(
      'PATCH',
      Uri.parse('$apiBaseUrl/api/v1/medicines/$id'),
      body: input.toJson(),
    );
    return Medicine.fromJson(payload as Map<String, dynamic>);
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
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ),
        'PATCH' => await _client.patch(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      };
    } catch (_) {
      throw const MedicineApiException(
        'Không thể kết nối dịch vụ thuốc. Vui lòng thử lại.',
      );
    }

    dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } catch (_) {
      payload = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? payload['message']
          : null;
      throw MedicineApiException(
        message is String
            ? message
            : 'Yêu cầu thất bại (${response.statusCode}).',
      );
    }
    return payload;
  }

  void close() => _client.close();
}
