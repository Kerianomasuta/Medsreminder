import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

abstract interface class DeviceLocationProvider {
  Future<DeviceLocation> currentLocation();
}

class DeviceLocationService implements DeviceLocationProvider {
  DeviceLocationService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  bool _isDefaultEmulatorLocation(double lat, double lng) {
    // Tọa độ mặc định của Google Emulator tại Mountain View, California (~37.422, -122.084)
    return (lat >= 37.35 && lat <= 37.50) && (lng >= -122.20 && lng <= -122.00);
  }

  Future<DeviceLocation?> _fetchLocationFromIp() async {
    try {
      final response = await _client
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final lat = (data['lat'] as num?)?.toDouble();
          final lon = (data['lon'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            return DeviceLocation(latitude: lat, longitude: lon);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<DeviceLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      final ipLoc = await _fetchLocationFromIp();
      if (ipLoc != null) return ipLoc;
      throw const DeviceLocationException(
        'Dịch vụ vị trí đang tắt. Hãy bật GPS/vị trí trên thiết bị.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      final ipLoc = await _fetchLocationFromIp();
      if (ipLoc != null) return ipLoc;
      throw const DeviceLocationException(
        'Bạn chưa cho phép ứng dụng truy cập vị trí.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      final ipLoc = await _fetchLocationFromIp();
      if (ipLoc != null) return ipLoc;
      throw const DeviceLocationException(
        'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật lại trong Cài đặt ứng dụng.',
      );
    }

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      position ??= await Geolocator.getLastKnownPosition();

      if (position != null) {
        // Nếu đang ở tọa độ mặc định của máy ảo Android Studio (Mỹ), tự động lấy vị trí thật qua IP
        if (_isDefaultEmulatorLocation(position.latitude, position.longitude)) {
          final ipLoc = await _fetchLocationFromIp();
          if (ipLoc != null) return ipLoc;
        }

        return DeviceLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      final ipLoc = await _fetchLocationFromIp();
      if (ipLoc != null) return ipLoc;

      throw const DeviceLocationException(
        'Không lấy được vị trí hiện tại. Hãy kiểm tra GPS và thử lại.',
      );
    } catch (e) {
      if (e is DeviceLocationException) rethrow;
      final ipLoc = await _fetchLocationFromIp();
      if (ipLoc != null) return ipLoc;
      throw const DeviceLocationException(
        'Không lấy được vị trí hiện tại. Hãy kiểm tra GPS và thử lại.',
      );
    }
  }
}
