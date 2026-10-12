import { describe, expect, it } from 'vitest';
import {
  encodeGeohash,
  geohashWithNeighbors,
  SEARCH_GEOHASH_PRECISION,
} from './geohash.js';

describe('geohash', () => {
  it('encodes the canonical public geohash example', () => {
    expect(encodeGeohash(42.6, -5.6, 5)).toBe('ezs42');
  });

  it('returns the current cell and adjacent cells for a radius query', () => {
    const latitude = 10.7769;
    const longitude = 106.7009;
    const hashes = geohashWithNeighbors(latitude, longitude);

    expect(hashes).toContain(
      encodeGeohash(latitude, longitude, SEARCH_GEOHASH_PRECISION),
    );
    expect(new Set(hashes).size).toBe(hashes.length);
    expect(hashes.length).toBeGreaterThanOrEqual(4);
    expect(hashes.length).toBeLessThanOrEqual(9);
  });

  it('rejects out-of-range values', () => {
    expect(() => encodeGeohash(91, 0)).toThrow(RangeError);
    expect(() => encodeGeohash(0, 181)).toThrow(RangeError);
    expect(() => encodeGeohash(0, 0, 0)).toThrow(RangeError);
  });
});
