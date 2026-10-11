const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

String encodeGeohash(double latitude, double longitude, {int precision = 9}) {
  if (!latitude.isFinite || latitude < -90 || latitude > 90) {
    throw RangeError.range(latitude, -90, 90, 'latitude');
  }
  if (!longitude.isFinite || longitude < -180 || longitude > 180) {
    throw RangeError.range(longitude, -180, 180, 'longitude');
  }
  if (precision < 1 || precision > 12) {
    throw RangeError.range(precision, 1, 12, 'precision');
  }

  var latMin = -90.0;
  var latMax = 90.0;
  var lngMin = -180.0;
  var lngMax = 180.0;
  var evenBit = true;
  var bit = 0;
  var character = 0;
  final result = StringBuffer();

  while (result.length < precision) {
    if (evenBit) {
      final midpoint = (lngMin + lngMax) / 2;
      if (longitude >= midpoint) {
        character = (character << 1) | 1;
        lngMin = midpoint;
      } else {
        character <<= 1;
        lngMax = midpoint;
      }
    } else {
      final midpoint = (latMin + latMax) / 2;
      if (latitude >= midpoint) {
        character = (character << 1) | 1;
        latMin = midpoint;
      } else {
        character <<= 1;
        latMax = midpoint;
      }
    }
    evenBit = !evenBit;
    bit += 1;
    if (bit == 5) {
      result.write(_base32[character]);
      bit = 0;
      character = 0;
    }
  }
  return result.toString();
}
