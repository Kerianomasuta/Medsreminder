import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { ILike, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { Pharmacy } from './schema/pharmacy.entity.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type PharmacyPayload = {
  pharmacistId?: string;
  name?: string;
  phone?: string;
  addressText?: string;
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

  async create(payload: PharmacyPayload) {
    const pharmacy = this.pharmacies.create({
      pharmacistId: this.requireUuid(payload.pharmacistId, 'pharmacistId'),
      name: this.requireText(payload.name, 'name'),
      phone: this.requireText(payload.phone, 'phone'),
      addressText: this.requireText(payload.addressText, 'addressText'),
      latitude: this.requireCoordinate(payload.latitude, 'latitude', -90, 90),
      longitude: this.requireCoordinate(payload.longitude, 'longitude', -180, 180),
      isActive: true,
    });

    return this.toResponse(await this.pharmacies.save(pharmacy));
  }

  async list(search?: string) {
    const term = search?.trim().replace(/[%_\\]/g, '');
    const rows = await this.pharmacies.find({
      where: term ? { name: ILike(`%${term}%`) } : undefined,
      order: { name: 'ASC' },
    });
    return rows.map((row) => this.toResponse(row));
  }

  async getById(id: string) {
    return this.toResponse(await this.findPharmacy(id));
  }

  async update(id: string, payload: PharmacyPayload) {
    const fields = ['pharmacistId', 'name', 'phone', 'addressText', 'latitude', 'longitude', 'isActive'] as const;
    if (!fields.some((field) => payload[field] !== undefined)) {
      throw ErrorHandling.BadRequest('Provide at least one field to update');
    }

    const pharmacy = await this.findPharmacy(id);
    if (payload.pharmacistId !== undefined) {
      pharmacy.pharmacistId = this.requireUuid(payload.pharmacistId, 'pharmacistId');
    }
    if (payload.name !== undefined) {
      pharmacy.name = this.requireText(payload.name, 'name');
    }
    if (payload.phone !== undefined) {
      pharmacy.phone = this.requireText(payload.phone, 'phone');
    }
    if (payload.addressText !== undefined) {
      pharmacy.addressText = this.requireText(payload.addressText, 'addressText');
    }
    if (payload.latitude !== undefined) {
      pharmacy.latitude = this.requireCoordinate(payload.latitude, 'latitude', -90, 90);
    }
    if (payload.longitude !== undefined) {
      pharmacy.longitude = this.requireCoordinate(payload.longitude, 'longitude', -180, 180);
    }
    if (payload.isActive !== undefined) {
      if (typeof payload.isActive !== 'boolean') {
        throw ErrorHandling.BadRequest('isActive must be true or false');
      }
      pharmacy.isActive = payload.isActive;
    }

    return this.toResponse(await this.pharmacies.save(pharmacy));
  }

  private async findPharmacy(id: string) {
    this.requireUuid(id, 'pharmacy id');
    const pharmacy = await this.pharmacies.findOne({ where: { id } });
    if (!pharmacy) {
      throw ErrorHandling.NotFound('Pharmacy not found');
    }
    return pharmacy;
  }

  private requireUuid(value: string | undefined, label: string) {
    if (!value || !UUID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be a UUID`);
    }
    return value;
  }

  private requireText(value: string | undefined, label: string) {
    const trimmed = value?.trim();
    if (!trimmed) {
      throw ErrorHandling.BadRequest(`${label} is required`);
    }
    return trimmed;
  }

  private requireCoordinate(value: number | undefined, label: string, min: number, max: number) {
    if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max) {
      throw ErrorHandling.BadRequest(`${label} must be a number from ${min} to ${max}`);
    }
    return value.toFixed(6);
  }

  private toResponse(pharmacy: Pharmacy) {
    return {
      id: pharmacy.id,
      pharmacistId: pharmacy.pharmacistId,
      name: pharmacy.name,
      phone: pharmacy.phone,
      addressText: pharmacy.addressText,
      latitude: Number(pharmacy.latitude),
      longitude: Number(pharmacy.longitude),
      isActive: pharmacy.isActive,
      createdAt: pharmacy.createdAt,
      updatedAt: pharmacy.updatedAt,
    };
  }
}
