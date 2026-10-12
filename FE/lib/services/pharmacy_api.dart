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

  Future<List<Pharmacy>> list({
    double? latitude,
    double? longitude,
    String? geohash,
    double? radiusKm,
  }) async {
    final query = <String, String>{};
    if (latitude != null) query['latitude'] = '$latitude';
    if (longitude != null) query['longitude'] = '$longitude';
    if (geohash != null) query['geohash'] = geohash;
    if (radiusKm != null) query['radiusKm'] = '$radiusKm';
    final uri = Uri.parse('$apiBaseUrl/api/v1/pharmacies')
        .replace(queryParameters: query.isEmpty ? null : query);
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

  Future<Pharmacy> getForPharmacist(String pharmacistId) async {
    final pharmacies = await list();
    final summary = pharmacies.where(
      (pharmacy) => pharmacy.pharmacistId == pharmacistId,
    );
    if (summary.isEmpty) {
      throw const PharmacyApiException('Không tìm thấy hồ sơ nhà thuốc.');
    }
    return getById(summary.first.id);
  }

  Future<Map<String, dynamic>> _map(String method, Uri uri) async {
    final payload = await _request(method, uri);
    if (payload is! Map<String, dynamic>) {
      throw const PharmacyApiException('Phản hồi nhà thuốc không hợp lệ.');
    }
    return payload;
  }

  Future<dynamic> _request(String method, Uri uri) async {
    late http.Response response;
    try {
      response = switch (method) {
        'GET' => await _client.get(uri),
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
