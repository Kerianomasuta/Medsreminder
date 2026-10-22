import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { ListPharmaciesQueryDto } from './list-pharmacies.query.js';

describe('ListPharmaciesQueryDto', () => {
  it('accepts the legacy isActive query flag for older app builds', async () => {
    const query = plainToInstance(ListPharmaciesQueryDto, {
      isActive: 'true',
      latitude: '10.7769',
      longitude: '106.7009',
      geohash: 'w3gvk1xyz',
      radiusKm: '10',
    });

    await expect(validate(query, { whitelist: true })).resolves.toEqual([]);
    expect(query.isActive).toBe(true);
  });

  it('still rejects invalid legacy isActive values', async () => {
    const query = plainToInstance(ListPharmaciesQueryDto, {
      isActive: 'yes',
    });

    const errors = await validate(query, { whitelist: true });

    expect(errors[0]?.property).toBe('isActive');
    expect(errors[0]?.constraints).toHaveProperty('isBoolean');
  });
});
