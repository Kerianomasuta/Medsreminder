import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { ListPharmaciesQueryDto } from './dto/list-pharmacies.query.js';

export type RegisterPharmacyInput = {
  pharmacistId: string;
  name: string;
  phoneNumber: string;
  addressText: string;
  latitude: number;
  longitude: number;
};

@Injectable()
export class PharmaciesService {
  constructor(
    @Inject('PHARMACY_ORDER_SERVICE')
    private readonly pharmacyClient: ClientProxy,
  ) {}

  createForRegistration(input: RegisterPharmacyInput) {
    return this.send({ cmd: 'create_pharmacy' }, input);
  }

  list(query: ListPharmaciesQueryDto) {
    return this.send({ cmd: 'list_pharmacies' }, query);
  }

  getById(id: string) {
    return this.send({ cmd: 'get_pharmacy' }, { id });
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
