import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    this.isApproximate = false,
    this.notice,
  });

  final double latitude;
  final double longitude;
  final bool isApproximate;
  final String? notice;
}

abstract interface class DeviceLocationProvider {
  Future<DeviceLocation> currentLocation();
}

abstract interface class DeviceGeolocator {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition(LocationSettings settings);
  Future<Position?> getLastKnownPosition();
}

class PluginDeviceGeolocator implements DeviceGeolocator {
  const PluginDeviceGeolocator();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) =>
      Geolocator.getCurrentPosition(locationSettings: settings);

  @override
  Future<Position?> getLastKnownPosition() => Geolocator.getLastKnownPosition();
}

class DeviceLocationService implements DeviceLocationProvider {
  DeviceLocationService({
    http.Client? client,
    DeviceGeolocator? geolocator,
    this.gpsTimeout = const Duration(seconds: 8),
    this.mobileGpsTimeout = const Duration(seconds: 15),
    this.networkTimeout = const Duration(seconds: 5),
    bool? isWeb,
  }) : _client = client ?? http.Client(),
       _geolocator = geolocator ?? const PluginDeviceGeolocator(),
       _isWeb = isWeb ?? kIsWeb;

  final http.Client _client;
  final DeviceGeolocator _geolocator;
  final Duration gpsTimeout;
  final Duration mobileGpsTimeout;
  final Duration networkTimeout;
  final bool _isWeb;

  bool _isDefaultEmulatorLocation(double lat, double lng) {
    // Tọa độ mặc định của Google Emulator tại Mountain View, California.
    return (lat >= 37.35 && lat <= 37.50) && (lng >= -122.20 && lng <= -122.00);
  }

  Future<DeviceLocation?> _fetchLocationFromIp({String? notice}) async {
    try {
      final response = await _client
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(networkTimeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['success'] != true) return null;

      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return null;

      return DeviceLocation(
        latitude: latitude,
        longitude: longitude,
        isApproximate: true,
        notice: notice ?? 'Không lấy được GPS mới nên ứng dụng đang dùng vị trí gần đúng theo mạng.',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DeviceLocation> currentLocation() async {
    if (!_isWeb) {
      bool serviceEnabled;
      try {
        serviceEnabled = await _geolocator.isLocationServiceEnabled().timeout(
          const Duration(seconds: 3),
        );
      } catch (_) {
        return _fallbackOrThrow(
          'Không kiểm tra được dịch vụ vị trí. Hãy bật GPS và thử lại.',
        );
      }
      if (!serviceEnabled) {
        return _fallbackOrThrow(
          'Dịch vụ vị trí đang tắt. Hãy bật GPS/vị trí trên thiết bị.',
        );
      }
    }

    LocationPermission permission;
    try {
      permission = await _geolocator.checkPermission().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {
      permission = LocationPermission.unableToDetermine;
    }

    if (!_isWeb && permission == LocationPermission.denied) {
      try {
        permission = await _geolocator.requestPermission().timeout(gpsTimeout);
      } catch (_) {
        return _fallbackOrThrow(
          'Không nhận được phản hồi cấp quyền vị trí. Hãy thử lại.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _fallbackOrThrow(
        _isWeb
            ? 'Quyền vị trí đang bị chặn. Hãy cho phép vị trí trong thanh địa chỉ của trình duyệt.'
            : 'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật lại trong Cài đặt ứng dụng.',
      );
    }
    if (!_isWeb && permission == LocationPermission.denied) {
      return _fallbackOrThrow('Bạn chưa cho phép ứng dụng truy cập vị trí.');
    }

    try {
      final settings = _isWeb
          ? WebSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: gpsTimeout,
              maximumAge: Duration.zero,
            )
          : LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              timeLimit: mobileGpsTimeout,
            );
      final position = await _geolocator
          .getCurrentPosition(settings)
          // geolocator_web currently passes microseconds to a browser API that
          // expects milliseconds, so enforce the real deadline in Dart too.
          .timeout(_isWeb ? gpsTimeout : mobileGpsTimeout);

      if (!_isWeb &&
          DateTime.now().difference(position.timestamp).abs() >
              const Duration(minutes: 2)) {
        throw const DeviceLocationException(
          'Thiết bị chỉ trả về một tọa độ cũ.',
        );
      }

      if (_isDefaultEmulatorLocation(position.latitude, position.longitude)) {
        final ipLocation = await _fetchLocationFromIp(
          notice: 'Máy ảo đang ở tọa độ mặc định. Ứng dụng đang dùng vị trí gần đúng theo mạng; hãy cập nhật Location trong Extended Controls để kiểm thử chính xác.',
        );
        if (ipLocation != null) return ipLocation;
      }

      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        notice: position.isMocked
            ? 'Đây là vị trí GPS giả lập. Máy ảo không tự đi theo vị trí thật; hãy cập nhật Location trong Extended Controls khi đổi nơi.'
            : null,
      );
    } catch (_) {
      if (!_isWeb) {
        try {
          final lastKnown = await _geolocator.getLastKnownPosition().timeout(
            const Duration(seconds: 2),
          );
          if (lastKnown != null && _isRecentAccuratePosition(lastKnown)) {
            return DeviceLocation(
              latitude: lastKnown.latitude,
              longitude: lastKnown.longitude,
              isApproximate: true,
              notice: 'GPS mới chưa phản hồi; ứng dụng đang dùng vị trí gần nhất trong vòng 30 giây.',
            );
          }
        } catch (_) {}
      }

      return _fallbackOrThrow(
        _isWeb
            ? 'Không lấy được vị trí chính xác. Hãy kiểm tra quyền vị trí của trình duyệt và thử lại.'
            : 'Không lấy được vị trí hiện tại. Hãy kiểm tra GPS và thử lại.',
      );
    }
  }

  bool _isRecentAccuratePosition(Position position) {
    final age = DateTime.now().difference(position.timestamp).abs();
    return age <= const Duration(seconds: 30) &&
        position.hasAccuracy &&
        position.accuracy.isFinite &&
        position.accuracy <= 250 &&
        !_isDefaultEmulatorLocation(position.latitude, position.longitude);
  }

  Future<DeviceLocation> _fallbackOrThrow(String message) async {
    final ipLocation = await _fetchLocationFromIp();
    if (ipLocation != null) return ipLocation;
    throw DeviceLocationException(message);
  }
}
