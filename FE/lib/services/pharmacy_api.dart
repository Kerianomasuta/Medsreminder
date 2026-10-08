import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pharmacist_dashboard.dart';
import 'api_base_url.dart';
import 'http_client_factory.dart';

class PharmacyApiException implements Exception {
  const PharmacyApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PharmacyApi {
  PharmacyApi({http.Client? client}) : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<Pharmacy> create(PharmacyInput input) async => Pharmacy.fromJson(
    await _map(
      'POST',
      Uri.parse('$apiBaseUrl/api/v1/pharmacies'),
      body: input.toJson(),
    ),
  );

  Future<List<Pharmacy>> list({bool? isActive}) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/pharmacies').replace(
      queryParameters: isActive == null ? null : {'isActive': '$isActive'},
    );
    final payload = await _request('GET', uri);
    return (payload as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Pharmacy.fromJson)
        .toList(growable: false);
  }

  Future<Pharmacy> getById(String id) async => Pharmacy.fromJson(
    await _map(
      'GET',
      Uri.parse('$apiBaseUrl/api/v1/pharmacies/${Uri.encodeComponent(id)}'),
    ),
  );

  Future<Pharmacy> update(String id, PharmacyInput input) async =>
      Pharmacy.fromJson(
        await _map(
          'PATCH',
          Uri.parse('$apiBaseUrl/api/v1/pharmacies/${Uri.encodeComponent(id)}'),
          body: input.toJson(includeOwner: false),
        ),
      );

  Future<List<PharmacyInventoryItem>> listInventory(String pharmacyId) async {
    final payload = await _request(
      'GET',
      Uri.parse(
        '$apiBaseUrl/api/v1/pharmacies/${Uri.encodeComponent(pharmacyId)}/inventory',
      ),
    );
    return (payload as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PharmacyInventoryItem.fromJson)
        .toList(growable: false);
  }

  Future<List<PharmacyInventoryItem>> upsertInventory(
    String pharmacyId,
    List<InventoryInput> items,
  ) async {
    final payload = await _request(
      'PUT',
      Uri.parse(
        '$apiBaseUrl/api/v1/pharmacies/${Uri.encodeComponent(pharmacyId)}/inventory',
      ),
      body: {'items': items.map((item) => item.toJson()).toList()},
    );
    return (payload as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PharmacyInventoryItem.fromJson)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _map(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final payload = await _request(method, uri, body: body);
    if (payload is! Map<String, dynamic>) {
      throw const PharmacyApiException('Phản hồi nhà thuốc không hợp lệ.');
    }
    return payload;
  }

  Future<dynamic> _request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    late http.Response response;
    try {
      final headers = body == null
          ? null
          : const {'Content-Type': 'application/json; charset=utf-8'};
      final encoded = body == null ? null : jsonEncode(body);
      response = switch (method) {
        'GET' => await _client.get(uri),
        'POST' => await _client.post(uri, headers: headers, body: encoded),
        'PATCH' => await _client.patch(uri, headers: headers, body: encoded),
        'PUT' => await _client.put(uri, headers: headers, body: encoded),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      };
    } catch (error) {
      if (error is PharmacyApiException) rethrow;
      throw const PharmacyApiException(
        'Không thể kết nối dịch vụ nhà thuốc. Vui lòng thử lại.',
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
      throw PharmacyApiException(
        message ?? 'Yêu cầu thất bại (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  void close() => _client.close();
}
