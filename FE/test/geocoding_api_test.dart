import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/geocoding_api.dart';

void main() {
  test('searches Vietnamese addresses and parses valid locations', () async {
    late http.Request captured;
    final api = GeocodingApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode([
            {
              'display_name': '123 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
              'lat': '10.77421',
              'lon': '106.70332',
            },
            {'display_name': 'Kết quả lỗi', 'lat': 'not-a-number', 'lon': '1'},
          ]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final results = await api.searchAddress('123 Nguyễn Huệ');

    expect(captured.url.path, '/search');
    expect(captured.url.queryParameters['countrycodes'], 'vn');
    expect(captured.url.queryParameters['q'], '123 Nguyễn Huệ');
    expect(captured.headers['User-Agent'], 'MedsReminder/1.0');
    expect(results, hasLength(1));
    expect(results.single.addressText, contains('Nguyễn Huệ'));
    expect(results.single.latitude, 10.77421);
    expect(results.single.longitude, 106.70332);
  });

  test('reverse geocodes the selected coordinates', () async {
    late http.Request captured;
    final api = GeocodingApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'display_name': 'Chợ Bến Thành, Quận 1'}),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await api.reverseGeocode(10.7725, 106.698);

    expect(captured.url.path, '/reverse');
    expect(captured.url.queryParameters['lat'], '10.7725');
    expect(captured.url.queryParameters['lon'], '106.698');
    expect(result.addressText, 'Chợ Bến Thành, Quận 1');
    expect(result.latitude, 10.7725);
  });

  test('reports a readable error when geocoding is unavailable', () async {
    final api = GeocodingApi(
      client: MockClient((_) async => http.Response('busy', 503)),
    );

    expect(
      () => api.searchAddress('Nhà thuốc Quận 1'),
      throwsA(
        isA<GeocodingApiException>().having(
          (error) => error.message,
          'message',
          contains('503'),
        ),
      ),
    );
  });
}
