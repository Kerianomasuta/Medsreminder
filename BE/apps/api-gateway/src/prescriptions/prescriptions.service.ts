import { Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { toRpcHttpException } from '../rpc-http-exception.js';
import { CreatePrescriptionItemDto, CreatePrescriptionDto } from './dto/create-prescription.dto.js';
import { ListPrescriptionsQueryDto } from './dto/list-prescriptions.query.js';
import { UpdatePrescriptionItemDto } from './dto/update-prescription-item.dto.js';
import { UpdatePrescriptionDto } from './dto/update-prescription.dto.js';

type AccessUser = {
  userId: string;
  role: string;
};

@Injectable()
export class PrescriptionsService {
  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
  ) {}

  create(dto: CreatePrescriptionDto, user: AccessUser) {
    return this.send({ cmd: 'create_prescription' }, { ...dto, ...this.actor(user) });
  }

  list(query: ListPrescriptionsQueryDto, user: AccessUser) {
    return this.send({ cmd: 'list_prescriptions' }, { ...query, ...this.actor(user) });
  }

  getById(id: string, user: AccessUser) {
    return this.send({ cmd: 'get_prescription' }, { id, ...this.actor(user) });
  }

  update(id: string, dto: UpdatePrescriptionDto, user: AccessUser) {
    return this.send({ cmd: 'update_prescription' }, { id, ...dto, ...this.actor(user) });
  }

  addItem(id: string, dto: CreatePrescriptionItemDto, user: AccessUser) {
    return this.send({ cmd: 'add_prescription_item' }, { prescriptionId: id, ...dto, ...this.actor(user) });
  }

  updateItem(id: string, dto: UpdatePrescriptionItemDto, user: AccessUser) {
    return this.send({ cmd: 'update_prescription_item' }, { id, ...dto, ...this.actor(user) });
  }

  private actor(user: AccessUser) {
    return { actorUserId: user.userId, actorRole: user.role };
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
