import { Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { toRpcHttpException } from '../rpc-http-exception.js';
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
    return toRpcHttpException(error, 'Medication service is unavailable');
  }
}
