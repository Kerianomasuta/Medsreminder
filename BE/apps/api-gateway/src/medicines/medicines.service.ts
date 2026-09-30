import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { CreateMedicineDto } from './dto/create-medicine.dto.js';
import { UpdateMedicineDto } from './dto/update-medicine.dto.js';

@Injectable()
export class MedicinesService {
  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
  ) {}

  create(dto: CreateMedicineDto) {
    return this.send({ cmd: 'create_medicine' }, dto);
  }

  list(search?: string) {
    return this.send({ cmd: 'list_medicines' }, { search });
  }

  getById(id: string) {
    return this.send({ cmd: 'get_medicine' }, { id });
  }

  update(id: string, dto: UpdateMedicineDto) {
    return this.send({ cmd: 'update_medicine' }, { id, ...dto });
  }

  private async send<T>(pattern: { cmd: string }, payload: unknown): Promise<T> {
    try {
      return await lastValueFrom(this.medicationClient.send<T>(pattern, payload));
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

    return new HttpException('Medication service is unavailable', HttpStatus.SERVICE_UNAVAILABLE);
  }
}
