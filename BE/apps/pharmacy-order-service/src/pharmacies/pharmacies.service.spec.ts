import { beforeEach, describe, expect, it, vi } from 'vitest';
import { FindOperator } from 'typeorm';
import { encodeGeohash } from './geohash.js';
import { PharmaciesService } from './pharmacies.service.js';

const pharmacistId = '507f1f77bcf86cd799439013';
const pharmacyId = '11111111-1111-4111-8111-111111111111';
const latitude = 10.7769;
const longitude = 106.7009;

function pharmacy(overrides: Record<string, unknown> = {}) {
  return {
    id: pharmacyId,
    pharmacistId,
    name: 'An Tam',
    phoneNumber: '0901234567',
    addressText: 'District 1, Ho Chi Minh City',
    latitude,
    longitude,
    geohash: encodeGeohash(latitude, longitude),
    createdAt: new Date('2026-10-09T00:00:00.000Z'),
    updatedAt: new Date('2026-10-09T00:00:00.000Z'),
    ...overrides,
  };
}

describe('PharmaciesService geospatial search', () => {
  let repository: {
    findOne: ReturnType<typeof vi.fn>;
    find: ReturnType<typeof vi.fn>;
    create: ReturnType<typeof vi.fn>;
    save: ReturnType<typeof vi.fn>;
  };
  let service: PharmaciesService;

  beforeEach(() => {
    repository = {
      findOne: vi.fn(async () => null),
      find: vi.fn(async () => []),
      create: vi.fn((value) => value),
      save: vi.fn(async (value) => pharmacy(value)),
    };
    service = new PharmaciesService(repository as never);
  });

  it('stores a server-generated geohash when creating a pharmacy', async () => {
    const created = await service.create({
      pharmacistId,
      name: ' An Tam ',
      phoneNumber: '0901234567',
      addressText: ' District 1, Ho Chi Minh City ',
      latitude,
      longitude,
    });

    expect(repository.create).toHaveBeenCalledWith(
      expect.objectContaining({
        geohash: encodeGeohash(latitude, longitude),
        name: 'An Tam',
        addressText: 'District 1, Ho Chi Minh City',
      }),
    );
    expect(created.geohash).toBe(encodeGeohash(latitude, longitude));
  });

  it('uses geohash prefixes, then enforces and sorts by the 10 km distance', async () => {
    repository.find.mockResolvedValue([
      pharmacy({ id: 'near', latitude: 10.78, longitude: 106.7 }),
      pharmacy({ id: 'far', latitude: 10.95, longitude: 106.7 }),
      pharmacy({ id: 'closest', latitude: 10.777, longitude: 106.701 }),
    ]);

    const result = await service.list({
      latitude,
      longitude,
      geohash: encodeGeohash(latitude, longitude),
      radiusKm: 10,
    });

    expect(result.map((item) => item.id)).toEqual(['closest', 'near']);
    expect(result.every((item) => (item.distanceKm ?? 11) <= 10)).toBe(true);
    const options = repository.find.mock.calls[0][0] as {
      where: Array<{ geohash: FindOperator<string> }>;
    };
    expect(options.where).toHaveLength(9);
    expect(
      options.where.every((item) => item.geohash instanceof FindOperator),
    ).toBe(true);
  });

  it('rejects a geohash that does not represent the supplied coordinates', async () => {
    await expect(
      service.list({
        latitude,
        longitude,
        geohash: encodeGeohash(21.0285, 105.8542),
        radiusKm: 10,
      }),
    ).rejects.toMatchObject({
      message: 'geohash does not match latitude and longitude',
    });
    expect(repository.find).not.toHaveBeenCalled();
  });

  it('rejects a radius greater than 10 km', async () => {
    await expect(
      service.list({ latitude, longitude, radiusKm: 10.1 }),
    ).rejects.toMatchObject({
      message: 'radiusKm must be greater than 0 and at most 10',
    });
  });
});
