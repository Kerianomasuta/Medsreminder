import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { CreatePrescriptionItemDto, CreatePrescriptionDto } from './dto/create-prescription.dto.js';
import { ListPrescriptionsQueryDto } from './dto/list-prescriptions.query.js';
import { UpdatePrescriptionItemDto } from './dto/update-prescription-item.dto.js';
import { UpdatePrescriptionDto } from './dto/update-prescription.dto.js';
import { UpdateScheduleRuleDto } from './dto/update-schedule-rule.dto.js';

@Injectable()
export class PrescriptionsService {
  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
  ) {}

  create(dto: CreatePrescriptionDto) {
    return this.send({ cmd: 'create_prescription' }, dto);
  }

  list(query: ListPrescriptionsQueryDto) {
    return this.send({ cmd: 'list_prescriptions' }, query);
  }

  getById(id: string) {
    return this.send({ cmd: 'get_prescription' }, { id });
  }

  update(id: string, dto: UpdatePrescriptionDto) {
    return this.send({ cmd: 'update_prescription' }, { id, ...dto });
  }

  addItem(id: string, dto: CreatePrescriptionItemDto) {
    return this.send({ cmd: 'add_prescription_item' }, { prescriptionId: id, ...dto });
  }

  updateItem(id: string, dto: UpdatePrescriptionItemDto) {
    return this.send({ cmd: 'update_prescription_item' }, { id, ...dto });
  }

  updateSchedule(id: string, dto: UpdateScheduleRuleDto) {
    return this.send({ cmd: 'update_schedule_rule' }, { id, ...dto });
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
