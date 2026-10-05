import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { CreateInventoryDto, UpdateInventoryDto } from './dto/create-inventory.dto.js';
import { CreatePharmacyDto, UpdatePharmacyDto } from './dto/create-pharmacy.dto.js';
import { ListPharmaciesQueryDto } from './dto/list-pharmacies.query.js';

@Injectable()
export class PharmaciesService {
  constructor(
    @Inject('PHARMACY_SERVICE')
    private readonly pharmacyClient: ClientProxy,
  ) {}

  create(dto: CreatePharmacyDto) {
    return this.send({ cmd: 'create_pharmacy' }, dto);
  }

  list(query: ListPharmaciesQueryDto) {
    return this.send({ cmd: 'list_pharmacies' }, query);
  }

  getById(id: string) {
    return this.send({ cmd: 'get_pharmacy' }, { id });
  }

  update(id: string, dto: UpdatePharmacyDto) {
    return this.send({ cmd: 'update_pharmacy' }, { id, ...dto });
  }

  listInventory(pharmacyId: string) {
    return this.send({ cmd: 'list_pharmacy_inventory' }, { pharmacyId });
  }

  addInventory(pharmacyId: string, dto: CreateInventoryDto) {
    return this.send({ cmd: 'add_pharmacy_inventory' }, { pharmacyId, ...dto });
  }

  updateInventory(id: string, dto: UpdateInventoryDto) {
    return this.send({ cmd: 'update_pharmacy_inventory' }, { id, ...dto });
  }

  private async send<T>(pattern: { cmd: string }, payload: unknown): Promise<T> {
    try {
      return await lastValueFrom(this.pharmacyClient.send<T>(pattern, payload));
    } catch (error) {
      throw this.toHttpException(error);
    }
  }

  private toHttpException(error: unknown) {
    if (error instanceof HttpException) {
      return error;
    }

    if (typeof error === 'object' && error !== null) {
      const record = error as { status?: number; message?: unknown };
      if (typeof record.status === 'number' && typeof record.message === 'string') {
        return new HttpException(record.message, record.status);
      }
    }

    return new HttpException('Pharmacy service is unavailable', HttpStatus.SERVICE_UNAVAILABLE);
  }
}
