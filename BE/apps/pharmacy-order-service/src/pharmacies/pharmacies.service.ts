import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Like, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import {
  encodeGeohash,
  geohashWithNeighbors,
  SEARCH_GEOHASH_PRECISION,
} from './geohash.js';
import { Pharmacy } from './schema/pharmacy.entity.js';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const OBJECT_ID_PATTERN = /^[0-9a-f]{24}$/i;

export type PharmacyInput = {
  pharmacistId?: string;
  name?: string;
  phoneNumber?: string;
  addressText?: string;
  latitude?: number;
  longitude?: number;
};

export type ListPharmaciesInput = {
  latitude?: number;
  longitude?: number;
  geohash?: string;
  radiusKm?: number;
};

const MAX_SEARCH_RADIUS_KM = 10;

@Injectable()
export class PharmaciesService {
  constructor(
    @InjectRepository(Pharmacy)
    private readonly pharmacies: Repository<Pharmacy>,
  ) {}

  async create(payload: PharmacyInput) {
    const pharmacistId = this.requireObjectId(
      payload.pharmacistId,
      'pharmacistId',
    );
    const existing = await this.pharmacies.findOne({ where: { pharmacistId } });
    if (existing) {
      throw ErrorHandling.Conflict('This pharmacist already has a pharmacy');
    }
    const pharmacy = this.pharmacies.create(
      this.preparePharmacy({ ...payload, pharmacistId }, true),
    );
    return this.toPharmacy(await this.pharmacies.save(pharmacy));
  }

  async list(query: ListPharmaciesInput = {}) {
    const located = this.hasCoordinates(query.latitude, query.longitude);
    const radiusKm = located ? this.requireRadius(query.radiusKm) : undefined;
    let rows: Pharmacy[];
    if (located) {
      const latitude = query.latitude as number;
      const longitude = query.longitude as number;
      this.validateClientGeohash(query.geohash, latitude, longitude);
      const prefixes = geohashWithNeighbors(latitude, longitude);
      rows = await this.pharmacies.find({
        where: prefixes.map((geohash) => ({
          geohash: Like(`${geohash}%`),
        })),
        order: { name: 'ASC' },
      });
    } else {
      rows = await this.pharmacies.find({
        order: { name: 'ASC' },
      });
    }
    return rows
      .map((row) => {
        const pharmacy = this.toPharmacy(row);
        if (!located) {
          return pharmacy;
        }
        return {
          ...pharmacy,
          distanceKm: this.distanceKm(
            query.latitude as number,
            query.longitude as number,
            row.latitude,
            row.longitude,
          ),
        };
      })
      .filter(
        (pharmacy) =>
          !located || (pharmacy.distanceKm ?? Infinity) <= (radiusKm as number),
      )
      .sort((left, right) => {
        if (!located) {
          return left.name.localeCompare(right.name);
        }
        return (left.distanceKm ?? 0) - (right.distanceKm ?? 0);
      });
  }

  async getById(id: string) {
    return this.toPharmacy(await this.findPharmacy(id));
  }

  private async findPharmacy(id: string) {
    const pharmacyId = this.requireUuid(id, 'pharmacyId');
    const pharmacy = await this.pharmacies.findOne({
      where: { id: pharmacyId },
    });
    if (!pharmacy) {
      throw ErrorHandling.NotFound('Pharmacy not found');
    }
    return pharmacy;
  }

  private preparePharmacy(payload: PharmacyInput, creating: boolean) {
    const changes: Partial<Pharmacy> = {};
    if (creating || payload.pharmacistId !== undefined) {
      changes.pharmacistId = this.requireObjectId(
        payload.pharmacistId,
        'pharmacistId',
      );
    }
    if (creating || payload.name !== undefined) {
      changes.name = this.requireText(payload.name, 'name', 150);
    }
    if (creating || payload.phoneNumber !== undefined) {
      changes.phoneNumber = this.requireText(
        payload.phoneNumber,
        'phoneNumber',
        15,
      );
    }
    if (creating || payload.addressText !== undefined) {
      changes.addressText = this.requireText(
        payload.addressText,
        'addressText',
        2000,
      );
    }
    if (
      creating ||
      payload.latitude !== undefined ||
      payload.longitude !== undefined
    ) {
      changes.latitude = this.requireCoordinate(
        payload.latitude,
        'latitude',
        -90,
        90,
      );
      changes.longitude = this.requireCoordinate(
        payload.longitude,
        'longitude',
        -180,
        180,
      );
      changes.geohash = encodeGeohash(changes.latitude, changes.longitude);
    }
    return changes;
  }

  private toPharmacy(pharmacy: Pharmacy) {
    return {
      id: pharmacy.id,
      pharmacistId: pharmacy.pharmacistId,
      name: pharmacy.name,
      phoneNumber: pharmacy.phoneNumber,
      addressText: pharmacy.addressText,
      latitude: pharmacy.latitude,
      longitude: pharmacy.longitude,
      geohash: pharmacy.geohash,
      createdAt: pharmacy.createdAt,
      updatedAt: pharmacy.updatedAt,
      distanceKm: undefined as number | undefined,
    };
  }

  private hasCoordinates(
    latitude: number | undefined,
    longitude: number | undefined,
  ) {
    if (latitude === undefined && longitude === undefined) {
      return false;
    }
    this.requireCoordinate(latitude, 'latitude', -90, 90);
    this.requireCoordinate(longitude, 'longitude', -180, 180);
    return true;
  }

  private requireRadius(value: number | undefined) {
    const radius = value ?? MAX_SEARCH_RADIUS_KM;
    if (
      !Number.isFinite(radius) ||
      radius <= 0 ||
      radius > MAX_SEARCH_RADIUS_KM
    ) {
      throw ErrorHandling.BadRequest(
        `radiusKm must be greater than 0 and at most ${MAX_SEARCH_RADIUS_KM}`,
      );
    }
    return radius;
  }

  private validateClientGeohash(
    value: string | undefined,
    latitude: number,
    longitude: number,
  ) {
    if (value === undefined) return;
    const normalized = value.trim().toLowerCase();
    if (!/^[0-9bcdefghjkmnpqrstuvwxyz]{4,12}$/.test(normalized)) {
      throw ErrorHandling.BadRequest('geohash is invalid');
    }
    const expected = encodeGeohash(latitude, longitude, normalized.length);
    if (expected !== normalized) {
      throw ErrorHandling.BadRequest(
        'geohash does not match latitude and longitude',
      );
    }
    if (
      !geohashWithNeighbors(
        latitude,
        longitude,
        SEARCH_GEOHASH_PRECISION,
      ).includes(expected.slice(0, SEARCH_GEOHASH_PRECISION))
    ) {
      throw ErrorHandling.BadRequest('geohash is outside the requested area');
    }
  }

  private distanceKm(
    fromLat: number,
    fromLng: number,
    toLat: number,
    toLng: number,
  ) {
    const earthRadiusKm = 6371;
    const latDelta = this.toRadians(toLat - fromLat);
    const lngDelta = this.toRadians(toLng - fromLng);
    const a =
      Math.sin(latDelta / 2) ** 2 +
      Math.cos(this.toRadians(fromLat)) *
        Math.cos(this.toRadians(toLat)) *
        Math.sin(lngDelta / 2) ** 2;
    return Math.round(earthRadiusKm * 2 * Math.asin(Math.sqrt(a)) * 100) / 100;
  }

  private toRadians(value: number) {
    return (value * Math.PI) / 180;
  }

  private requireUuid(value: string | undefined, label: string) {
    if (!value || !UUID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be a UUID`);
    }
    return value;
  }

  private requireObjectId(value: string | undefined, label: string) {
    if (!value || !OBJECT_ID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be an ObjectId`);
    }
    return value;
  }

  private requireText(
    value: string | undefined,
    label: string,
    maxLength: number,
  ) {
    const trimmed = value?.trim() ?? '';
    if (!trimmed) {
      throw ErrorHandling.BadRequest(`${label} is required`);
    }
    if (trimmed.length > maxLength) {
      throw ErrorHandling.BadRequest(
        `${label} must be at most ${maxLength} characters`,
      );
    }
    return trimmed;
  }

  private requireCoordinate(
    value: number | undefined,
    label: string,
    min: number,
    max: number,
  ) {
    if (
      typeof value !== 'number' ||
      !Number.isFinite(value) ||
      value < min ||
      value > max
    ) {
      throw ErrorHandling.BadRequest(
        `${label} must be between ${min} and ${max}`,
      );
    }
    return value;
  }
}
