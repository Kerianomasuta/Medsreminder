import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/utils/geohash.dart';

void main() {
  test('encodes the canonical geohash sample', () {
    expect(encodeGeohash(42.6, -5.6, precision: 5), 'ezs42');
  });

  test(
    'uses the same stable precision for pharmacy and caregiver locations',
    () {
      expect(encodeGeohash(10.7769, 106.7009), hasLength(9));
      expect(
        encodeGeohash(10.7769, 106.7009),
        encodeGeohash(10.7769, 106.7009),
      );
    },
  );

  test('rejects invalid coordinates and precision', () {
    expect(() => encodeGeohash(91, 106), throwsRangeError);
    expect(() => encodeGeohash(10, 181), throwsRangeError);
    expect(() => encodeGeohash(10, 106, precision: 0), throwsRangeError);
  });
}
