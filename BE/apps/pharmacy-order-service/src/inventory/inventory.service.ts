import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { Pharmacy } from '../pharmacies/schema/pharmacy.entity.js';
import { PharmacyInventory } from './schema/pharmacy-inventory.entity.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type InventoryPayload = {
  medicineId?: string;
  stockQuantity?: number;
  pricePerUnit?: number;
};

@Injectable()
export class InventoryService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(PharmacyInventory)
    private readonly inventory: Repository<PharmacyInventory>,
    @InjectRepository(Pharmacy)
    private readonly pharmacies: Repository<Pharmacy>,
  ) {}

  async list(pharmacyId?: string) {
    const id = this.requireUuid(pharmacyId, 'pharmacyId');
    await this.findPharmacy(id);
    const rows = await this.inventory.find({
      where: { pharmacyId: id },
      order: { createdAt: 'ASC' },
    });
    return rows.map((row) => this.toResponse(row));
  }

  async add(pharmacyId: string | undefined, payload: InventoryPayload) {
    const id = this.requireUuid(pharmacyId, 'pharmacyId');
    await this.findPharmacy(id);
    const medicineId = this.requireUuid(payload.medicineId, 'medicineId');
    await this.assertMedicineExists(medicineId);

    const existing = await this.inventory.findOne({ where: { pharmacyId: id, medicineId } });
    if (existing) {
      throw ErrorHandling.Conflict('This medicine is already in the pharmacy inventory');
    }

    const row = this.inventory.create({
      pharmacyId: id,
      medicineId,
      stockQuantity: payload.stockQuantity === undefined ? 0 : this.requireWholeNumber(payload.stockQuantity, 'stockQuantity'),
      pricePerUnit: this.requirePrice(payload.pricePerUnit),
    });

    return this.toResponse(await this.inventory.save(row));
  }

  async update(id: string, payload: InventoryPayload) {
    if (payload.stockQuantity === undefined && payload.pricePerUnit === undefined) {
      throw ErrorHandling.BadRequest('Provide at least one field to update');
    }

    this.requireUuid(id, 'inventory id');
    const row = await this.inventory.findOne({ where: { id } });
    if (!row) {
      throw ErrorHandling.NotFound('Inventory item not found');
    }
    if (payload.stockQuantity !== undefined) {
      row.stockQuantity = this.requireWholeNumber(payload.stockQuantity, 'stockQuantity');
    }
    if (payload.pricePerUnit !== undefined) {
      row.pricePerUnit = this.requirePrice(payload.pricePerUnit);
    }

    return this.toResponse(await this.inventory.save(row));
  }

  private async findPharmacy(id: string) {
    const pharmacy = await this.pharmacies.findOne({ where: { id } });
    if (!pharmacy) {
      throw ErrorHandling.NotFound('Pharmacy not found');
    }
    return pharmacy;
  }

  private async assertMedicineExists(medicineId: string) {
    const rows: Array<{ id: string }> = await this.dataSource.query(
      'SELECT id FROM medication.medicines WHERE id = $1',
      [medicineId],
    );
    if (!rows.length) {
      throw ErrorHandling.NotFound('Medicine not found');
    }
  }

  private requireUuid(value: string | undefined, label: string) {
    if (!value || !UUID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be a UUID`);
    }
    return value;
  }

  private requireWholeNumber(value: number, label: string) {
    if (!Number.isInteger(value) || value < 0) {
      throw ErrorHandling.BadRequest(`${label} must be a whole number of 0 or more`);
    }
    return value;
  }

  private requirePrice(value: number | undefined) {
    if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
      throw ErrorHandling.BadRequest('pricePerUnit must be 0 or more');
    }
    return value.toFixed(2);
  }

  private toResponse(row: PharmacyInventory) {
    return {
      id: row.id,
      pharmacyId: row.pharmacyId,
      medicineId: row.medicineId,
      stockQuantity: row.stockQuantity,
      pricePerUnit: Number(row.pricePerUnit),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }
}
