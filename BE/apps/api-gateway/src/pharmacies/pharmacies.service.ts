import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { CreatePharmacyDto } from './dto/create-pharmacy.dto.js';
import { ListPharmaciesQueryDto } from './dto/list-pharmacies.query.js';
import { UpdatePharmacyDto } from './dto/update-pharmacy.dto.js';
import { UpsertInventoryDto } from './dto/upsert-inventory.dto.js';

@Injectable()
export class PharmaciesService {
  constructor(
    @Inject('PHARMACY_ORDER_SERVICE')
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

  upsertInventory(pharmacyId: string, dto: UpsertInventoryDto) {
    return this.send({ cmd: 'upsert_pharmacy_inventory' }, { pharmacyId, items: dto.items });
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
    return new HttpException('Pharmacy order service is unavailable', HttpStatus.SERVICE_UNAVAILABLE);
  }
}
