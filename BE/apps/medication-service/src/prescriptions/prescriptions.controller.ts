import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { PrescriptionsService } from './prescriptions.service.js';

type ScheduleMessage = {
  reminderTime?: string;
  daysOfWeek?: number[];
};

type ItemMessage = {
  name?: string;
  genericName?: string | null;
  unit?: string;
  imageUrl?: string | null;
  dosagePerTime?: number;
  currentStock?: number;
  reorderThreshold?: number;
  instructions?: string | null;
  schedules?: ScheduleMessage[];
};

type ActorMessage = {
  actorUserId?: string;
  actorRole?: string;
};

type CreatePrescriptionMessage = ActorMessage & {
  patientId?: string;
  createdByCgId?: string;
  title?: string;
  doctorName?: string | null;
  prescriptionCode?: string | null;
  imagePrescriptionUrl?: string | null;
  startDate?: string;
  endDate?: string | null;
  items?: ItemMessage[];
};

type UpdatePrescriptionMessage = ActorMessage & {
  id: string;
  title?: string;
  doctorName?: string | null;
  prescriptionCode?: string | null;
  imagePrescriptionUrl?: string | null;
  startDate?: string;
  endDate?: string | null;
  isActive?: boolean;
};

@Controller()
export class PrescriptionsController {
  constructor(private readonly prescriptionsService: PrescriptionsService) {}

  @MessagePattern({ cmd: 'create_prescription' })
  create(@Payload() payload: CreatePrescriptionMessage) {
    return this.prescriptionsService.create(payload);
  }

  @MessagePattern({ cmd: 'list_prescriptions' })
  list(@Payload() payload: ActorMessage & { patientId?: string }) {
    return this.prescriptionsService.list(payload?.patientId, this.actor(payload));
  }

  @MessagePattern({ cmd: 'get_prescription' })
  getById(@Payload() payload: ActorMessage & { id: string }) {
    return this.prescriptionsService.getById(payload.id, this.actor(payload));
  }

  @MessagePattern({ cmd: 'update_prescription' })
  update(@Payload() payload: UpdatePrescriptionMessage) {
    const { id, actorUserId, actorRole, ...changes } = payload;
    return this.prescriptionsService.update(id, changes, { userId: actorUserId, role: actorRole });
  }

  @MessagePattern({ cmd: 'add_prescription_item' })
  addItem(@Payload() payload: ItemMessage & ActorMessage & { prescriptionId?: string }) {
    const { prescriptionId, actorUserId, actorRole, ...item } = payload;
    return this.prescriptionsService.addItem(prescriptionId, item, { userId: actorUserId, role: actorRole });
  }

  @MessagePattern({ cmd: 'replenish_prescription_stock' })
  replenishStock(
    @Payload() payload: { items?: Array<{ prescriptionItemId?: string; quantity?: number }> },
  ) {
    return this.prescriptionsService.replenishStock(payload?.items);
  }

  @MessagePattern({ cmd: 'update_prescription_item' })
  updateItem(
    @Payload() payload: ActorMessage & {
      id: string;
      name?: string;
      genericName?: string | null;
      unit?: string;
      imageUrl?: string | null;
      dosagePerTime?: number;
      currentStock?: number;
      reorderThreshold?: number;
      instructions?: string | null;
    },
  ) {
    const { id, actorUserId, actorRole, ...changes } = payload;
    return this.prescriptionsService.updateItem(id, changes, { userId: actorUserId, role: actorRole });
  }

  private actor(payload?: ActorMessage) {
    if (!payload?.actorRole) {
      return undefined;
    }
    return { userId: payload.actorUserId, role: payload.actorRole };
  }
}
