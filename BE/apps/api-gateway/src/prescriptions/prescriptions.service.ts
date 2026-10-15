import { ForbiddenException, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { toRpcHttpException } from '../rpc-http-exception.js';
import { CreatePrescriptionItemDto, CreatePrescriptionDto } from './dto/create-prescription.dto.js';
import { ListPrescriptionsQueryDto } from './dto/list-prescriptions.query.js';
import { ScanPrescriptionDto } from './dto/scan-prescription.dto.js';
import { UpdatePrescriptionItemDto } from './dto/update-prescription-item.dto.js';
import { UpdatePrescriptionDto } from './dto/update-prescription.dto.js';

type ScannedDraft = {
  title: string;
  doctorName: string | null;
  prescriptionCode: string | null;
  startDate: string | null;
  endDate: string | null;
  items: CreatePrescriptionDto['items'];
};

type AccessUser = {
  userId: string;
  role: string;
};

@Injectable()
export class PrescriptionsService {
  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
    @Inject('AI_SERVICE')
    private readonly aiClient: ClientProxy,
    @Inject('USER_SERVICE')
    private readonly userClient: ClientProxy,
  ) {}

  async scan(dto: ScanPrescriptionDto, user: AccessUser) {
    if (user.role !== 'ADMIN') {
      const access = await this.sendTo<{ isPremium?: boolean }>(
        this.userClient,
        { cmd: 'handle_get_premium' },
        { userId: user.userId },
        'User service is unavailable',
      );
      if (access?.isPremium !== true) {
        throw new ForbiddenException('Scanning a paper prescription requires a premium account');
      }
    }

    const draft = await this.sendTo<ScannedDraft>(
      this.aiClient,
      { cmd: 'scan_prescription' },
      { imageUrl: dto.imagePrescriptionUrl },
      'AI service is unavailable',
    );
    const startDate = dto.startDate ?? draft.startDate ?? todayInVietnam();
    const endDate = dto.endDate ?? draft.endDate ?? undefined;
    return this.create({
      patientId: dto.patientId,
      createdByCgId: dto.createdByCgId,
      title: draft.title,
      doctorName: draft.doctorName ?? undefined,
      prescriptionCode: draft.prescriptionCode ?? undefined,
      imagePrescriptionUrl: dto.imagePrescriptionUrl,
      startDate,
      endDate,
      items: draft.items,
    }, user);
  }

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

  private send<T>(pattern: { cmd: string }, payload: unknown) {
    return this.sendTo<T>(this.medicationClient, pattern, payload, 'Medication service is unavailable');
  }

  private async sendTo<T>(
    client: ClientProxy,
    pattern: { cmd: string },
    payload: unknown,
    unavailableMessage: string,
  ): Promise<T> {
    try {
      return await lastValueFrom(client.send<T>(pattern, payload));
    } catch (error) {
      throw toRpcHttpException(error, unavailableMessage);
    }
  }
}

function todayInVietnam() {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' }).format(new Date());
}
