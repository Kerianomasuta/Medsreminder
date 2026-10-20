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
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const _photonBaseUrl = 'https://photon.komoot.io';
  static const _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const _minimumRequestInterval = Duration(milliseconds: 300);
  static const _requestTimeout = Duration(seconds: 10);

  final http.Client _client;
  final bool _ownsClient;
  Future<void> _requestGate = Future.value();
  DateTime? _lastRequestAt;

  Future<List<PharmacyLocationSelection>> searchAddress(String query) async {
    final normalized = query.trim();
    if (normalized.length < 3) return const [];

    // 1. Thử Photon API trước (rất nhanh, miễn phí, không bị chặn tại VN)
    try {
      final photonUri = Uri.parse('$_photonBaseUrl/api/').replace(
        queryParameters: {
          'q': normalized,
          'limit': '5',
          'lang': 'default',
        },
      );
      final payload = await _get(photonUri);
      if (payload is Map<String, dynamic> && payload['features'] is List) {
        final list = <PharmacyLocationSelection>[];
        for (final feature in payload['features'] as List) {
          if (feature is Map<String, dynamic>) {
            final parsed = _parsePhotonFeature(feature);
            if (parsed != null) list.add(parsed);
          }
        }
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // Nếu Photon lỗi, fallback tiếp tục
    }

    // 2. Fallback sang Nominatim
    try {
      final nominatimUri = Uri.parse('$_nominatimBaseUrl/search').replace(
        queryParameters: {
          'format': 'jsonv2',
          'q': normalized,
          'limit': '5',
          'countrycodes': 'vn',
          'addressdetails': '1',
          'accept-language': 'vi',
        },
      );
      final payload = await _get(nominatimUri);
      if (payload is List<dynamic>) {
        final list = payload
            .whereType<Map<String, dynamic>>()
            .map(_parseLocation)
            .whereType<PharmacyLocationSelection>()
            .toList(growable: false);
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // Ignored
    }

    return const [];
  }

  Future<PharmacyLocationSelection> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    // 1. Thử Photon Reverse trước
    try {
      final photonUri = Uri.parse('$_photonBaseUrl/reverse').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
        },
      );
      final payload = await _get(photonUri);
      if (payload is Map<String, dynamic> && payload['features'] is List) {
        final features = payload['features'] as List;
        if (features.isNotEmpty && features.first is Map<String, dynamic>) {
          final parsed = _parsePhotonFeature(features.first as Map<String, dynamic>);
          if (parsed != null) return parsed;
        }
      }
    } catch (_) {
      // Fallback
    }

    // 2. Fallback Nominatim Reverse
    try {
      final payload = await _get(
        Uri.parse('$_nominatimBaseUrl/reverse').replace(
          queryParameters: {
            'format': 'jsonv2',
            'lat': latitude.toString(),
            'lon': longitude.toString(),
            'addressdetails': '1',
            'accept-language': 'vi',
          },
        ),
      );
      if (payload is Map<String, dynamic>) {
        final address = payload['display_name']?.toString().trim() ?? '';
        if (address.isNotEmpty) {
          return PharmacyLocationSelection(
            addressText: address,
            latitude: latitude,
            longitude: longitude,
          );
        }
      }
    } catch (_) {
      // Ignored
    }

    // Nếu cả 2 đều không lấy được tên địa chỉ, trả về tên tọa độ hiện tại
    final latStr = latitude.toStringAsFixed(5);
    final lonStr = longitude.toStringAsFixed(5);
    return PharmacyLocationSelection(
      addressText: 'Vị trí hiện tại ($latStr, $lonStr)',
      latitude: latitude,
      longitude: longitude,
    );
  }

  PharmacyLocationSelection? _parsePhotonFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List?;
    if (coordinates == null || coordinates.length < 2) return null;

    final lon = (coordinates[0] as num?)?.toDouble();
    final lat = (coordinates[1] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final parts = <String>[];

    final name = properties['name']?.toString().trim();
    if (name != null && name.isNotEmpty) parts.add(name);

    final street = properties['street']?.toString().trim();
    if (street != null && street.isNotEmpty && street != name) parts.add(street);

    final district = (properties['district'] ?? properties['locality'])?.toString().trim();
    if (district != null && district.isNotEmpty) parts.add(district);

    final city = (properties['city'] ?? properties['state'])?.toString().trim();
    if (city != null && city.isNotEmpty) parts.add(city);

    final address = parts.isNotEmpty
        ? parts.join(', ')
        : 'Vị trí (${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)})';

    return PharmacyLocationSelection(
      addressText: address,
      latitude: lat,
      longitude: lon,
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
              if (!kIsWeb) ...{
                'User-Agent': 'MedsReminderApp/1.0.0 (contact: support@medsreminder.duckdns.org)',
                'Referer': 'https://medsreminder.duckdns.org',
              },
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
    if (_ownsClient) {
      _client.close();
    }
  }
}
