const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

export const PHARMACY_GEOHASH_PRECISION = 9;
export const SEARCH_GEOHASH_PRECISION = 4;

export function encodeGeohash(
  latitude: number,
  longitude: number,
  precision = PHARMACY_GEOHASH_PRECISION,
) {
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
    throw new RangeError('latitude must be between -90 and 90');
  }
  if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
    throw new RangeError('longitude must be between -180 and 180');
  }
  if (!Number.isInteger(precision) || precision < 1 || precision > 12) {
    throw new RangeError('precision must be an integer between 1 and 12');
  }

  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;
  let evenBit = true;
  let bit = 0;
  let character = 0;
  let result = '';

  while (result.length < precision) {
    if (evenBit) {
      const midpoint = (lngMin + lngMax) / 2;
      if (longitude >= midpoint) {
        character = (character << 1) | 1;
        lngMin = midpoint;
      } else {
        character <<= 1;
        lngMax = midpoint;
      }
    } else {
      const midpoint = (latMin + latMax) / 2;
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
    if (bit === 5) {
      result += BASE32[character];
      bit = 0;
      character = 0;
    }
  }
  return result;
}

export function geohashWithNeighbors(
  latitude: number,
  longitude: number,
  precision = SEARCH_GEOHASH_PRECISION,
) {
  const bounds = decodeBounds(encodeGeohash(latitude, longitude, precision));
  const latStep = bounds.maxLatitude - bounds.minLatitude;
  const lngStep = bounds.maxLongitude - bounds.minLongitude;
  const hashes = new Set<string>();

  for (let row = -1; row <= 1; row += 1) {
    for (let column = -1; column <= 1; column += 1) {
      const neighborLatitude = Math.max(
        -90,
        Math.min(90, latitude + row * latStep),
      );
      let neighborLongitude = longitude + column * lngStep;
      if (neighborLongitude > 180) neighborLongitude -= 360;
      if (neighborLongitude < -180) neighborLongitude += 360;
      hashes.add(encodeGeohash(neighborLatitude, neighborLongitude, precision));
    }
  }
  return [...hashes];
}

function decodeBounds(geohash: string) {
  let minLatitude = -90;
  let maxLatitude = 90;
  let minLongitude = -180;
  let maxLongitude = 180;
  let evenBit = true;

  for (const character of geohash) {
    const value = BASE32.indexOf(character);
    if (value < 0)
      throw new RangeError('geohash contains an invalid character');
    for (let mask = 16; mask > 0; mask >>= 1) {
      if (evenBit) {
        const midpoint = (minLongitude + maxLongitude) / 2;
        if ((value & mask) !== 0) minLongitude = midpoint;
        else maxLongitude = midpoint;
      } else {
        const midpoint = (minLatitude + maxLatitude) / 2;
        if ((value & mask) !== 0) minLatitude = midpoint;
        else maxLatitude = midpoint;
      }
      evenBit = !evenBit;
    }
  }
  return { minLatitude, maxLatitude, minLongitude, maxLongitude };
}
