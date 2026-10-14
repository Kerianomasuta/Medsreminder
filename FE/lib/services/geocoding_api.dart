import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/pharmacist_dashboard.dart';

class GeocodingApiException implements Exception {
  const GeocodingApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeocodingApi {
  GeocodingApi({http.Client? client})
    // Nominatim is a public, cross-origin service. It must not use the app's
    // authenticated web client because that client sends requests with
    // credentials, while Nominatim allows CORS with a wildcard origin.
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _minimumRequestInterval = Duration(seconds: 1);
  static const _requestTimeout = Duration(seconds: 8);

  final http.Client _client;
  final bool _ownsClient;
  Future<void> _requestGate = Future.value();
  DateTime? _lastRequestAt;

  Future<List<PharmacyLocationSelection>> searchAddress(String query) async {
    final normalized = query.trim();
    if (normalized.length < 3) return const [];

    final payload = await _get(
      Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'format': 'jsonv2',
          'q': normalized,
          'limit': '5',
          'countrycodes': 'vn',
          'addressdetails': '1',
          'accept-language': 'vi',
        },
      ),
    );
    if (payload is! List<dynamic>) {
      throw const GeocodingApiException(
        'Dịch vụ bản đồ trả về dữ liệu không hợp lệ.',
      );
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(_parseLocation)
        .whereType<PharmacyLocationSelection>()
        .toList(growable: false);
  }

  Future<PharmacyLocationSelection> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final payload = await _get(
      Uri.parse('$_baseUrl/reverse').replace(
        queryParameters: {
          'format': 'jsonv2',
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'addressdetails': '1',
          'accept-language': 'vi',
        },
      ),
    );
    if (payload is! Map<String, dynamic>) {
      throw const GeocodingApiException(
        'Không thể xác định địa chỉ tại vị trí đã chọn.',
      );
    }
    final address = payload['display_name']?.toString().trim() ?? '';
    if (address.isEmpty) {
      throw const GeocodingApiException(
        'Không thể xác định địa chỉ tại vị trí đã chọn.',
      );
    }
    return PharmacyLocationSelection(
      addressText: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  PharmacyLocationSelection? _parseLocation(Map<String, dynamic> json) {
    final address = json['display_name']?.toString().trim() ?? '';
    final latitude = double.tryParse(json['lat']?.toString() ?? '');
    final longitude = double.tryParse(json['lon']?.toString() ?? '');
    if (address.isEmpty ||
        latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return PharmacyLocationSelection(
      addressText: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<dynamic> _get(Uri uri) async {
    await _waitForRequestSlot();
    late http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (!kIsWeb) 'User-Agent': 'MedsReminder/1.0',
            },
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const GeocodingApiException(
        'Dịch vụ bản đồ phản hồi quá lâu. Vui lòng thử lại.',
      );
    } catch (_) {
      throw const GeocodingApiException(
        'Không thể kết nối dịch vụ bản đồ. Vui lòng thử lại.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeocodingApiException(
        'Dịch vụ bản đồ đang bận (${response.statusCode}). Vui lòng thử lại.',
      );
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const GeocodingApiException(
        'Dịch vụ bản đồ trả về dữ liệu không hợp lệ.',
      );
    }
  }

  Future<void> _waitForRequestSlot() {
    final request = _requestGate.then((_) async {
      final lastRequestAt = _lastRequestAt;
      if (lastRequestAt != null) {
        final wait =
            _minimumRequestInterval - DateTime.now().difference(lastRequestAt);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastRequestAt = DateTime.now();
    });
    _requestGate = request;
    return request;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
