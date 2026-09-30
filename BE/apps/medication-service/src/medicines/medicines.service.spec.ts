import { RpcException } from '@nestjs/microservices';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { MedicineUnit } from '../enums/medicine-unit.enum.js';
import { MedicinesService } from './medicines.service.js';

const medicineId = '8d8b6f3e-4c1a-4f0b-9c2d-123456789abc';

function createRepository() {
  return {
    create: vi.fn((value) => value),
    save: vi.fn(async (value) => ({
      id: medicineId,
      createdAt: new Date('2026-09-30T00:00:00.000Z'),
      updatedAt: new Date('2026-09-30T00:00:00.000Z'),
      ...value,
    })),
    find: vi.fn(),
    findOne: vi.fn(),
  };
}

describe('MedicinesService', () => {
  let repository: ReturnType<typeof createRepository>;
  let service: MedicinesService;

  beforeEach(() => {
    repository = createRepository();
    service = new MedicinesService(repository as never);
  });

  it('stores a catalog medicine with trimmed text', async () => {
    const created = await service.create({
      name: '  Paracetamol ',
      genericName: ' Acetaminophen ',
      unit: MedicineUnit.VIEN,
      instructionNote: '  ',
    });

    expect(repository.create).toHaveBeenCalledWith({
      name: 'Paracetamol',
      genericName: 'Acetaminophen',
      unit: MedicineUnit.VIEN,
      instructionNote: null,
      imageUrl: null,
    });
    expect(created.name).toBe('Paracetamol');
    expect(created.unit).toBe(MedicineUnit.VIEN);
  });

  it('rejects a medicine without a name', async () => {
    await expect(service.create({ name: ' ', unit: MedicineUnit.GOI })).rejects.toBeInstanceOf(RpcException);
  });

  it('returns not found when the id is missing', async () => {
    repository.findOne.mockResolvedValue(null);

    await expect(service.getById(medicineId)).rejects.toMatchObject({
      message: 'Medicine not found',
    });
  });
});
