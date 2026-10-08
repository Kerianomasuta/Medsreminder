import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/models/pharmacist_dashboard.dart';
import 'package:meds_reminder/services/geocoding_api.dart';
import 'package:meds_reminder/widgets/pharmacy_location_picker.dart';

void main() {
  testWidgets('search result confirms address and coordinates', (tester) async {
    PharmacyLocationSelection? selected;
    final api = GeocodingApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'display_name': '123 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
              'lat': '10.77421',
              'lon': '106.70332',
            },
          ]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PharmacyLocationPicker(
            geocodingApi: api,
            showMap: false,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('pharmacy-address-search')),
      '123 Nguyễn Huệ',
    );
    await tester.tap(find.byKey(const Key('search-pharmacy-address')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('address-result-0')));
    await tester.pump();

    expect(
      find.byKey(const Key('confirmed-pharmacy-location')),
      findsOneWidget,
    );
    expect(selected?.addressText, contains('Nguyễn Huệ'));
    expect(selected?.latitude, 10.77421);
    expect(selected?.longitude, 106.70332);
  });

  testWidgets('editing a confirmed address invalidates its coordinates', (
    tester,
  ) async {
    PharmacyLocationSelection? selected = const PharmacyLocationSelection(
      addressText: 'Địa chỉ cũ',
      latitude: 10.77,
      longitude: 106.7,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PharmacyLocationPicker(
            initialLocation: selected,
            showMap: false,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('pharmacy-address-search')),
      'Địa chỉ mới',
    );
    await tester.pump();

    expect(selected, isNull);
    expect(find.byKey(const Key('confirmed-pharmacy-location')), findsNothing);
    expect(find.textContaining('chọn lại vị trí'), findsOneWidget);
  });
}
