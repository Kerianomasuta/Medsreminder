import 'package:geolocator/geolocator.dart';

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
  @override
  Future<DeviceLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceLocationException(
        'Dịch vụ vị trí đang tắt. Hãy bật GPS/vị trí trên thiết bị.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(
        'Bạn chưa cho phép ứng dụng truy cập vị trí.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật lại trong Cài đặt ứng dụng.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      throw const DeviceLocationException(
        'Không lấy được vị trí hiện tại. Hãy kiểm tra GPS và thử lại.',
      );
    }
  }
}
