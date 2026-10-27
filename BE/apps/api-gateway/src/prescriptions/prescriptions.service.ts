import { BadRequestException, ForbiddenException, Inject, Injectable, Logger } from '@nestjs/common';
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

type MedicineName = {
  name: string;
  genericName: string | null;
};

type ItemBrief = MedicineName & {
  patientId: string;
};

type DrugInteraction = {
  checked: boolean;
  hasWarning: boolean;
  summary: string;
};

const UNCHECKED: DrugInteraction = {
  checked: false,
  hasWarning: false,
  summary: 'Không kiểm tra được tương tác thuốc lúc này. Hãy hỏi bác sĩ hoặc dược sĩ trước khi uống thêm.',
};

const PREMIUM_ONLY: DrugInteraction = {
  checked: false,
  hasWarning: false,
  summary: 'Kiểm tra tương tác thuốc chỉ mở cho tài khoản Premium.',
};

@Injectable()
export class PrescriptionsService {
  private readonly logger = new Logger(PrescriptionsService.name);

  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
    @Inject('AI_SERVICE')
    private readonly aiClient: ClientProxy,
    @Inject('USER_SERVICE')
    private readonly userClient: ClientProxy,
  ) {}

  async scan(dto: ScanPrescriptionDto, image: Buffer, mimeType: string, user: AccessUser) {
    const normalizedType = imageContentType(image, mimeType);
    if (!normalizedType) {
      throw new BadRequestException('Ảnh đơn thuốc phải là JPEG, PNG hoặc WebP');
    }
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
      { imageBase64: image.toString('base64'), mimeType: normalizedType },
      'AI service is unavailable',
    );
    const startDate = dto.startDate ?? draft.startDate ?? todayInVietnam();
    const proposedEnd = dto.endDate ?? draft.endDate ?? undefined;
    const endDate = dto.endDate == null && proposedEnd != null && proposedEnd < startDate
      ? undefined
      : proposedEnd;
    const patientId = user.role === 'PATIENT' ? user.userId : dto.patientId;
    const current = await this.currentMedicines(patientId, user);
    return {
      patientId,
      title: draft.title,
      doctorName: draft.doctorName,
      prescriptionCode: draft.prescriptionCode,
      startDate,
      endDate: endDate ?? null,
      items: draft.items.map((item) => ({
        name: item.name,
        genericName: item.genericName ?? null,
        unit: item.unit,
        dosagePerTime: item.dosagePerTime,
        currentStock: item.currentStock ?? 0,
        reorderThreshold: item.reorderThreshold ?? 6,
        instructions: item.instructions ?? null,
        schedules: item.schedules.map((schedule) => ({
          reminderTime: schedule.reminderTime.slice(0, 5),
          daysOfWeek: schedule.daysOfWeek,
        })),
      })),
      interaction: await this.reviewInteraction(
        user,
        current,
        draft.items.map((item) => medicineLabel(item.name, item.genericName)),
        true,
      ),
    };
  }

  photo(id: string, user: AccessUser) {
    return this.send<{ contentType: string; imageBase64: string }>(
      { cmd: 'get_prescription_photo' },
      { id, ...this.actor(user) },
    );
  }

  async create(dto: CreatePrescriptionDto, user: AccessUser) {
    const patientId = user.role === 'PATIENT' ? user.userId : dto.patientId;
    const current = await this.currentMedicines(patientId, user);
    const saved = await this.send<Record<string, unknown>>(
      { cmd: 'create_prescription' },
      { ...dto, ...this.actor(user) },
    );
    return {
      ...saved,
      interaction: await this.reviewInteraction(
        user,
        current,
        dto.items.map((item) => medicineLabel(item.name, item.genericName)),
      ),
    };
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

  async addItem(id: string, dto: CreatePrescriptionItemDto, user: AccessUser) {
    const prescription = await this.getById(id, user) as { patientId?: string };
    const current = prescription.patientId
      ? await this.currentMedicines(prescription.patientId, user)
      : null;
    const saved = await this.send<Record<string, unknown>>(
      { cmd: 'add_prescription_item' },
      { prescriptionId: id, ...dto, ...this.actor(user) },
    );
    return {
      ...saved,
      interaction: await this.reviewInteraction(user, current, [medicineLabel(dto.name, dto.genericName)]),
    };
  }

  async updateItem(id: string, dto: UpdatePrescriptionItemDto, user: AccessUser) {
    const renamed = dto.name !== undefined || dto.genericName !== undefined;
    if (!renamed) {
    return this.send({ cmd: 'update_prescription_item' }, { id, ...dto, ...this.actor(user) });
    }
    const brief = await this.send<ItemBrief>(
      { cmd: 'get_prescription_item_brief' },
      { id, ...this.actor(user) },
    );
    const current = await this.currentMedicines(brief.patientId, user);
    const saved = await this.send<Record<string, unknown>>(
      { cmd: 'update_prescription_item' },
      { id, ...dto, ...this.actor(user) },
    );
    const previous = medicineLabel(brief.name, brief.genericName);
    const next = medicineLabel(
      dto.name ?? brief.name,
      dto.genericName !== undefined ? dto.genericName : brief.genericName,
    );
    if (sameMedicine(previous, next)) {
      return {
        ...saved,
        interaction: {
          checked: true,
          hasWarning: false,
          summary: 'Tên thuốc không đổi nên không kiểm tra lại tương tác.',
        },
      };
    }
    const others = withoutOne(current, previous);
    return {
      ...saved,
      interaction: await this.reviewInteraction(user, others, [next]),
    };
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

  private async currentMedicines(patientId: string, user: AccessUser) {
    try {
      const rows = await this.send<MedicineName[]>(
        { cmd: 'list_active_medicine_names' },
        { patientId, ...this.actor(user) },
      );
      return rows.map((row) => medicineLabel(row.name, row.genericName)).filter((label) => label.length > 0);
    } catch {
      this.logger.warn('Could not load active medicines for the interaction check');
      return null;
    }
  }

  private async reviewInteraction(
    user: AccessUser,
    current: string[] | null,
    incoming: string[],
    premiumAlreadyChecked = false,
  ): Promise<DrugInteraction> {
    if (current === null) {
      return UNCHECKED;
    }
    const names = incoming.filter((label) => label.length > 0);
    if (names.length === 0) {
      return { checked: true, hasWarning: false, summary: 'Không có tên thuốc để kiểm tra tương tác.' };
    }
    if (current.length === 0 && names.length < 2) {
      return { checked: true, hasWarning: false, summary: 'Chưa có thuốc khác đang dùng để đối chiếu.' };
    }
    const access = premiumAlreadyChecked ? 'yes' : await this.interactionAccess(user);
    if (access === 'no') {
      return PREMIUM_ONLY;
    }
    if (access === 'unknown') {
      return UNCHECKED;
    }
    try {
      return await this.sendTo<DrugInteraction>(
        this.aiClient,
        { cmd: 'check_drug_interaction' },
        { currentNames: current, newNames: names },
        'AI service is unavailable',
      );
    } catch {
      this.logger.warn('Drug interaction check failed');
      return UNCHECKED;
    }
  }

  private async interactionAccess(user: AccessUser): Promise<'yes' | 'no' | 'unknown'> {
    if (user.role === 'ADMIN') {
      return 'yes';
    }
    try {
      const premium = await this.sendTo<{ isPremium?: boolean }>(
        this.userClient,
        { cmd: 'handle_get_premium' },
        { userId: user.userId },
        'User service is unavailable',
      );
      return premium?.isPremium === true ? 'yes' : 'no';
    } catch {
      return 'unknown';
    }
  }
}

function imageContentType(image: Buffer, declared: string) {
  const mime = declared.split(';')[0].trim().toLowerCase();
  if (mime === 'image/jpg' || mime === 'image/jpeg' || mime === 'image/png' || mime === 'image/webp') {
    return mime === 'image/jpg' ? 'image/jpeg' : mime;
  }
  if (image.length >= 3 && image[0] === 0xff && image[1] === 0xd8 && image[2] === 0xff) {
    return 'image/jpeg';
  }
  if (image.length >= 4 && image[0] === 0x89 && image[1] === 0x50 && image[2] === 0x4e && image[3] === 0x47) {
    return 'image/png';
  }
  if (image.length >= 12 && image.toString('ascii', 0, 4) === 'RIFF' && image.toString('ascii', 8, 12) === 'WEBP') {
    return 'image/webp';
  }
  return '';
}

function todayInVietnam() {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' }).format(new Date());
}

function medicineLabel(name?: string | null, genericName?: string | null) {
  const medicine = cleanLabel(name);
  const generic = cleanLabel(genericName);
  if (!medicine) {
    return '';
  }
  if (!generic || sameMedicine(medicine, generic)) {
    return medicine;
  }
  return `${medicine} (${generic})`.slice(0, 160);
}

function cleanLabel(value?: string | null) {
  return (value ?? '').replace(/[\u0000-\u001F]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 120);
}

function sameMedicine(left: string, right: string) {
  return left.toLocaleLowerCase('vi') === right.toLocaleLowerCase('vi');
}

function withoutOne(labels: string[] | null, previous: string) {
  if (!labels) {
    return null;
  }
  const index = labels.findIndex((label) => sameMedicine(label, previous));
  if (index < 0) {
    return labels;
  }
  return labels.filter((_, itemIndex) => itemIndex !== index);
}
