import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/models/pharmacist_dashboard.dart';
import 'package:meds_reminder/services/device_location_service.dart';
import 'package:meds_reminder/services/geocoding_api.dart';
import 'package:meds_reminder/widgets/pharmacy_location_picker.dart';

class _FixedLocationProvider implements DeviceLocationProvider {
  const _FixedLocationProvider();

  @override
  Future<DeviceLocation> currentLocation() async =>
      const DeviceLocation(latitude: 10.77421, longitude: 106.70332);
}

class _FailingLocationProvider implements DeviceLocationProvider {
  const _FailingLocationProvider();

  @override
  Future<DeviceLocation> currentLocation() =>
      throw const DeviceLocationException('Không lấy được vị trí hiện tại.');
}

void main() {
  testWidgets('GPS confirms the reverse-geocoded pharmacy location', (
    tester,
  ) async {
    PharmacyLocationSelection? selected;
    Uri? reverseUri;
    final api = GeocodingApi(
      client: MockClient((request) async {
        reverseUri = request.url;
        return http.Response(
          jsonEncode({
            'display_name': '123 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PharmacyLocationPicker(
            geocodingApi: api,
            locationProvider: const _FixedLocationProvider(),
            showMap: false,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('pharmacy-address-search')), findsNothing);
    expect(find.byKey(const Key('search-pharmacy-address')), findsNothing);
    await tester.tap(find.byKey(const Key('use-current-pharmacy-location')));
    await tester.pumpAndSettle();

    expect(reverseUri?.path, '/reverse');
    expect(reverseUri?.queryParameters['lat'], '10.77421');
    expect(reverseUri?.queryParameters['lon'], '106.70332');
    expect(
      find.byKey(const Key('confirmed-pharmacy-location')),
      findsOneWidget,
    );
    expect(find.textContaining('123 Nguyễn Huệ'), findsOneWidget);
    expect(selected?.latitude, 10.77421);
    expect(selected?.longitude, 106.70332);
  });

  testWidgets('GPS failure is displayed without selecting a location', (
    tester,
  ) async {
    PharmacyLocationSelection? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PharmacyLocationPicker(
            locationProvider: const _FailingLocationProvider(),
            showMap: false,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('use-current-pharmacy-location')));
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(find.byKey(const Key('confirmed-pharmacy-location')), findsNothing);
    expect(find.textContaining('Không lấy được vị trí'), findsOneWidget);
  });
}
