import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { Pharmacy } from './schema/pharmacy.entity.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const OBJECT_ID_PATTERN = /^[0-9a-f]{24}$/i;

export type PharmacyInput = {
  pharmacistId?: string;
  name?: string;
  phoneNumber?: string;
  addressText?: string;
  latitude?: number;
  longitude?: number;
  isActive?: boolean;
};

export type ListPharmaciesInput = {
  latitude?: number;
  longitude?: number;
  isActive?: boolean;
};

@Injectable()
export class PharmaciesService {
  constructor(
    @InjectRepository(Pharmacy)
    private readonly pharmacies: Repository<Pharmacy>,
  ) {}

  async create(payload: PharmacyInput) {
    const pharmacistId = this.requireObjectId(payload.pharmacistId, 'pharmacistId');
    const existing = await this.pharmacies.findOne({ where: { pharmacistId } });
    if (existing) {
      throw ErrorHandling.Conflict('This pharmacist already has a pharmacy');
    }
    const pharmacy = this.pharmacies.create(this.preparePharmacy({ ...payload, pharmacistId }, true));
    return this.toPharmacy(await this.pharmacies.save(pharmacy));
  }

  async list(query: ListPharmaciesInput = {}) {
    const isActive = query.isActive === undefined ? true : this.requireBoolean(query.isActive, 'isActive');
    const rows = await this.pharmacies.find({
      where: { isActive },
      order: { name: 'ASC' },
    });
    const located = this.hasCoordinates(query.latitude, query.longitude);
    return rows
      .map((row) => {
        const pharmacy = this.toPharmacy(row);
        if (!located) {
          return pharmacy;
        }
        return {
          ...pharmacy,
          distanceKm: this.distanceKm(query.latitude as number, query.longitude as number, row.latitude, row.longitude),
        };
      })
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
    const pharmacy = await this.pharmacies.findOne({ where: { id: pharmacyId } });
    if (!pharmacy) {
      throw ErrorHandling.NotFound('Pharmacy not found');
    }
    return pharmacy;
  }

  private preparePharmacy(payload: PharmacyInput, creating: boolean) {
    const changes: Partial<Pharmacy> = {};
    if (creating || payload.pharmacistId !== undefined) {
      changes.pharmacistId = this.requireObjectId(payload.pharmacistId, 'pharmacistId');
    }
    if (creating || payload.name !== undefined) {
      changes.name = this.requireText(payload.name, 'name', 150);
    }
    if (creating || payload.phoneNumber !== undefined) {
      changes.phoneNumber = this.requireText(payload.phoneNumber, 'phoneNumber', 15);
    }
    if (creating || payload.addressText !== undefined) {
      changes.addressText = this.requireText(payload.addressText, 'addressText', 2000);
    }
    if (creating || payload.latitude !== undefined || payload.longitude !== undefined) {
      changes.latitude = this.requireCoordinate(payload.latitude, 'latitude', -90, 90);
      changes.longitude = this.requireCoordinate(payload.longitude, 'longitude', -180, 180);
    }
    if (payload.isActive !== undefined) {
      changes.isActive = this.requireBoolean(payload.isActive, 'isActive');
    } else if (creating) {
      changes.isActive = true;
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
      isActive: pharmacy.isActive,
      createdAt: pharmacy.createdAt,
      updatedAt: pharmacy.updatedAt,
      distanceKm: undefined as number | undefined,
    };
  }

  private hasCoordinates(latitude: number | undefined, longitude: number | undefined) {
    if (latitude === undefined && longitude === undefined) {
      return false;
    }
    this.requireCoordinate(latitude, 'latitude', -90, 90);
    this.requireCoordinate(longitude, 'longitude', -180, 180);
    return true;
  }

  private distanceKm(fromLat: number, fromLng: number, toLat: number, toLng: number) {
    const earthRadiusKm = 6371;
    const latDelta = this.toRadians(toLat - fromLat);
    const lngDelta = this.toRadians(toLng - fromLng);
    const a = Math.sin(latDelta / 2) ** 2
      + Math.cos(this.toRadians(fromLat)) * Math.cos(this.toRadians(toLat)) * Math.sin(lngDelta / 2) ** 2;
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

  private requireText(value: string | undefined, label: string, maxLength: number) {
    const trimmed = value?.trim() ?? '';
    if (!trimmed) {
      throw ErrorHandling.BadRequest(`${label} is required`);
    }
    if (trimmed.length > maxLength) {
      throw ErrorHandling.BadRequest(`${label} must be at most ${maxLength} characters`);
    }
    return trimmed;
  }

  private requireCoordinate(value: number | undefined, label: string, min: number, max: number) {
    if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max) {
      throw ErrorHandling.BadRequest(`${label} must be between ${min} and ${max}`);
    }
    return value;
  }

  private requireBoolean(value: boolean, label: string) {
    if (typeof value !== 'boolean') {
      throw ErrorHandling.BadRequest(`${label} must be true or false`);
    }
    return value;
  }
}
