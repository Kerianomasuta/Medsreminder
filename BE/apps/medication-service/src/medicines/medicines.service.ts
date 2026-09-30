import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { ILike, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { MedicineUnit } from '../enums/medicine-unit.enum.js';
import { Medicine } from './schema/medicine.entity.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type MedicinePayload = {
  name?: string;
  genericName?: string | null;
  unit?: string;
  instructionNote?: string | null;
  imageUrl?: string | null;
};

@Injectable()
export class MedicinesService {
  constructor(
    @InjectRepository(Medicine)
    private readonly medicines: Repository<Medicine>,
  ) {}

  async create(payload: MedicinePayload) {
    const medicine = this.medicines.create({
      name: this.requireName(payload.name),
      genericName: this.optionalText(payload.genericName),
      unit: this.requireUnit(payload.unit),
      instructionNote: this.optionalText(payload.instructionNote),
      imageUrl: this.optionalText(payload.imageUrl),
    });

    return this.toResponse(await this.medicines.save(medicine));
  }

  async list(search?: string) {
    const term = search?.trim().replace(/[%_\\]/g, '');
    const medicines = await this.medicines.find({
      where: term
        ? [{ name: ILike(`%${term}%`) }, { genericName: ILike(`%${term}%`) }]
        : undefined,
      order: { name: 'ASC' },
    });

    return medicines.map((medicine) => this.toResponse(medicine));
  }

  async getById(id: string) {
    return this.toResponse(await this.findMedicine(id));
  }

  async update(id: string, payload: MedicinePayload) {
    const hasChange = ['name', 'genericName', 'unit', 'instructionNote', 'imageUrl'].some(
      (field) => payload[field as keyof MedicinePayload] !== undefined,
    );

    if (!hasChange) {
      throw ErrorHandling.BadRequest('Provide at least one field to update');
    }

    const medicine = await this.findMedicine(id);

    if (payload.name !== undefined) {
      medicine.name = this.requireName(payload.name);
    }
    if (payload.genericName !== undefined) {
      medicine.genericName = this.optionalText(payload.genericName);
    }
    if (payload.unit !== undefined) {
      medicine.unit = this.requireUnit(payload.unit);
    }
    if (payload.instructionNote !== undefined) {
      medicine.instructionNote = this.optionalText(payload.instructionNote);
    }
    if (payload.imageUrl !== undefined) {
      medicine.imageUrl = this.optionalText(payload.imageUrl);
    }

    return this.toResponse(await this.medicines.save(medicine));
  }

  private async findMedicine(id: string) {
    if (!UUID_PATTERN.test(id)) {
      throw ErrorHandling.BadRequest('Medicine id must be a UUID');
    }

    const medicine = await this.medicines.findOne({ where: { id } });
    if (!medicine) {
      throw ErrorHandling.NotFound('Medicine not found');
    }

    return medicine;
  }

  private requireName(name: string | null | undefined) {
    const trimmed = name?.trim();
    if (!trimmed) {
      throw ErrorHandling.BadRequest('Medicine name is required');
    }
    return trimmed;
  }

  private requireUnit(unit: string | null | undefined): MedicineUnit {
    if (unit !== MedicineUnit.VIEN && unit !== MedicineUnit.GOI && unit !== MedicineUnit.CHAI) {
      throw ErrorHandling.BadRequest('Unit must be VIEN, GOI, or CHAI');
    }
    return unit;
  }

  private optionalText(value: string | null | undefined) {
    if (value == null) {
      return null;
    }
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
  }

  private toResponse(medicine: Medicine) {
    return {
      id: medicine.id,
      name: medicine.name,
      genericName: medicine.genericName,
      unit: medicine.unit,
      instructionNote: medicine.instructionNote,
      imageUrl: medicine.imageUrl,
      createdAt: medicine.createdAt,
      updatedAt: medicine.updatedAt,
    };
  }
}
