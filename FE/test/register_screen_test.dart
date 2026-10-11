import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/models/app_role.dart';
import 'package:meds_reminder/models/registration_input.dart';
import 'package:meds_reminder/screens/auth/register_screen.dart';
import 'package:meds_reminder/services/device_location_service.dart';
import 'package:meds_reminder/services/geocoding_api.dart';

class _FixedLocationProvider implements DeviceLocationProvider {
  const _FixedLocationProvider(this.location);

  final DeviceLocation location;

  @override
  Future<DeviceLocation> currentLocation() async => location;
}

void main() {
  testWidgets('pharmacist registration requires and submits pharmacy details', (
    tester,
  ) async {
    RegistrationInput? submitted;
    final geocodingApi = GeocodingApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'display_name': '123 Lê Lợi, Quận 1, TP.HCM'}),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(geocodingApi.close);
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          onRegister: (input) async => submitted = input,
          onBackToLogin: () {},
          geocodingApi: geocodingApi,
          locationProvider: const _FixedLocationProvider(
            DeviceLocation(latitude: 10.7769, longitude: 106.7009),
          ),
          showLocationMap: false,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('registration-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dược sĩ').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pharmacy-name')), findsOneWidget);
    expect(
      find.byKey(const Key('registration-pharmacy-location')),
      findsOneWidget,
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Dược sĩ Demo');
    await tester.enterText(fields.at(1), 'pharmacist@example.com');
    await tester.enterText(fields.at(2), '0912345678');
    await tester.enterText(find.byKey(const Key('pharmacy-name')), 'An Tâm');
    await tester.enterText(fields.at(4), 'password123');
    await tester.enterText(fields.at(5), 'password123');

    expect(find.byKey(const Key('pharmacy-address-search')), findsNothing);
    expect(find.byKey(const Key('search-pharmacy-address')), findsNothing);
    await tester.tap(find.byKey(const Key('use-current-pharmacy-location')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('registration-submit')));
    await tester.tap(find.byKey(const Key('registration-submit')));
    await tester.pumpAndSettle();

    expect(submitted?.role, AppRole.pharmacist);
    expect(submitted?.pharmacyName, 'An Tâm');
    expect(submitted?.addressText, '123 Lê Lợi, Quận 1, TP.HCM');
    expect(submitted?.latitude, 10.7769);
    expect(submitted?.longitude, 106.7009);
  });

  testWidgets('patient registration does not show pharmacy fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(onRegister: (_) async {}, onBackToLogin: () {}),
      ),
    );

    expect(find.byKey(const Key('pharmacy-name')), findsNothing);
    expect(
      find.byKey(const Key('registration-pharmacy-location')),
      findsNothing,
    );
  });

  testWidgets('pharmacist can use GPS and reverse geocode the address', (
    tester,
  ) async {
    RegistrationInput? submitted;
    Uri? reverseUri;
    final geocodingApi = GeocodingApi(
      client: MockClient((request) async {
        reverseUri = request.url;
        return http.Response(
          jsonEncode({'display_name': '123 Nguyễn Huệ, Quận 1, TP.HCM'}),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(geocodingApi.close);
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          onRegister: (input) async => submitted = input,
          onBackToLogin: () {},
          geocodingApi: geocodingApi,
          locationProvider: const _FixedLocationProvider(
            DeviceLocation(latitude: 10.7769, longitude: 106.7009),
          ),
          showLocationMap: false,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('registration-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dược sĩ').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-current-pharmacy-location')));
    await tester.pumpAndSettle();

    expect(reverseUri?.path, '/reverse');
    expect(reverseUri?.queryParameters['lat'], '10.7769');
    expect(reverseUri?.queryParameters['lon'], '106.7009');
    expect(
      find.byKey(const Key('confirmed-pharmacy-location')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('confirmed-pharmacy-geohash')), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Dược sĩ Demo');
    await tester.enterText(fields.at(1), 'pharmacist@example.com');
    await tester.enterText(fields.at(2), '0912345678');
    await tester.enterText(find.byKey(const Key('pharmacy-name')), 'An Tâm');
    await tester.enterText(fields.at(4), 'password123');
    await tester.enterText(fields.at(5), 'password123');
    await tester.ensureVisible(find.byKey(const Key('registration-submit')));
    await tester.tap(find.byKey(const Key('registration-submit')));
    await tester.pumpAndSettle();

    expect(submitted?.addressText, '123 Nguyễn Huệ, Quận 1, TP.HCM');
    expect(submitted?.latitude, 10.7769);
    expect(submitted?.longitude, 106.7009);
  });
}
