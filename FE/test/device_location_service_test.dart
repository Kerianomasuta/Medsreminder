import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/device_location_service.dart';

class _FakeGeolocator implements DeviceGeolocator {
  _FakeGeolocator({
    this.permission = LocationPermission.whileInUse,
    this.currentPosition,
    this.lastKnownPosition,
  });

  final LocationPermission permission;
  final Position? currentPosition;
  final Position? lastKnownPosition;
  int requestPermissionCalls = 0;
  int lastKnownPositionCalls = 0;
  LocationSettings? receivedSettings;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) {
    receivedSettings = settings;
    final position = currentPosition;
    return position == null
        ? Completer<Position>().future
        : Future.value(position);
  }

  @override
  Future<Position?> getLastKnownPosition() async {
    lastKnownPositionCalls += 1;
    return lastKnownPosition;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalls += 1;
    return permission;
  }
}

Position _position({
  required double latitude,
  required double longitude,
  required DateTime timestamp,
  double accuracy = 10,
  bool isMocked = false,
}) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: timestamp,
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: isMocked,
  hasAccuracy: true,
);

void main() {
  test('web GPS timeout falls back to an HTTPS IP location', () async {
    Uri? requestedUri;
    final geolocator = _FakeGeolocator(permission: LocationPermission.denied);
    final service = DeviceLocationService(
      isWeb: true,
      geolocator: geolocator,
      gpsTimeout: const Duration(milliseconds: 5),
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'success': true,
            'latitude': 10.7769,
            'longitude': 106.7009,
          }),
          200,
        );
      }),
    );

    final location = await service.currentLocation();

    expect(requestedUri?.scheme, 'https');
    expect(requestedUri?.host, 'ipwho.is');
    expect(location.latitude, 10.7769);
    expect(location.longitude, 106.7009);
    expect(location.isApproximate, isTrue);
    expect(geolocator.requestPermissionCalls, 0);
    expect(geolocator.lastKnownPositionCalls, 0);
  });

  test('web reports blocked permission when fallback is unavailable', () async {
    final geolocator = _FakeGeolocator(
      permission: LocationPermission.deniedForever,
    );
    final service = DeviceLocationService(
      isWeb: true,
      geolocator: geolocator,
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );

    await expectLater(
      service.currentLocation(),
      throwsA(
        isA<DeviceLocationException>().having(
          (error) => error.message,
          'message',
          contains('trình duyệt'),
        ),
      ),
    );
    expect(geolocator.requestPermissionCalls, 0);
  });

  test('mobile requests a fresh high-accuracy position', () async {
    final geolocator = _FakeGeolocator(
      currentPosition: _position(
        latitude: 10.7626,
        longitude: 106.6825,
        timestamp: DateTime.now(),
      ),
    );
    final service = DeviceLocationService(
      isWeb: false,
      geolocator: geolocator,
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );

    final location = await service.currentLocation();

    expect(location.latitude, 10.7626);
    expect(location.longitude, 106.6825);
    expect(geolocator.receivedSettings?.accuracy, LocationAccuracy.high);
    expect(geolocator.receivedSettings?.distanceFilter, 0);
    expect(geolocator.lastKnownPositionCalls, 0);
  });

  test(
    'mobile rejects a stale cached position and falls back to network',
    () async {
      final geolocator = _FakeGeolocator(
        lastKnownPosition: _position(
          latitude: 10.8000,
          longitude: 106.6000,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      );
      final service = DeviceLocationService(
        isWeb: false,
        geolocator: geolocator,
        mobileGpsTimeout: const Duration(milliseconds: 5),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'latitude': 10.7626,
              'longitude': 106.6825,
            }),
            200,
          ),
        ),
      );

      final location = await service.currentLocation();

      expect(location.latitude, 10.7626);
      expect(location.longitude, 106.6825);
      expect(location.isApproximate, isTrue);
      expect(location.notice, contains('gần đúng'));
      expect(geolocator.lastKnownPositionCalls, 1);
    },
  );

  test(
    'mobile reports when the current position comes from an emulator',
    () async {
      final geolocator = _FakeGeolocator(
        currentPosition: _position(
          latitude: 10.7626,
          longitude: 106.6825,
          timestamp: DateTime.now(),
          isMocked: true,
        ),
      );
      final service = DeviceLocationService(
        isWeb: false,
        geolocator: geolocator,
        client: MockClient((_) async => http.Response('unavailable', 503)),
      );

      final location = await service.currentLocation();

      expect(location.latitude, 10.7626);
      expect(location.notice, contains('GPS giả lập'));
    },
  );
}
