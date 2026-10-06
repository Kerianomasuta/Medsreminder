import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { PrescriptionsService } from './prescriptions.service.js';

type ScheduleMessage = {
  reminderTime?: string;
  daysOfWeek?: number[];
};

type ItemMessage = {
  medicineId?: string;
  dosagePerTime?: number;
  currentStock?: number;
  reorderThreshold?: number;
  instructions?: string | null;
  schedules?: ScheduleMessage[];
};

type CreatePrescriptionMessage = {
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

type UpdatePrescriptionMessage = {
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
  list(@Payload() payload: { patientId?: string }) {
    return this.prescriptionsService.list(payload?.patientId);
  }

  @MessagePattern({ cmd: 'get_prescription' })
  getById(@Payload() payload: { id: string }) {
    return this.prescriptionsService.getById(payload.id);
  }

  @MessagePattern({ cmd: 'update_prescription' })
  update(@Payload() payload: UpdatePrescriptionMessage) {
    const { id, ...changes } = payload;
    return this.prescriptionsService.update(id, changes);
  }

  @MessagePattern({ cmd: 'add_prescription_item' })
  addItem(@Payload() payload: ItemMessage & { prescriptionId?: string }) {
    const { prescriptionId, ...item } = payload;
    return this.prescriptionsService.addItem(prescriptionId, item);
  }

  @MessagePattern({ cmd: 'replenish_prescription_stock' })
  replenishStock(
    @Payload() payload: { items?: Array<{ prescriptionItemId?: string; quantity?: number }> },
  ) {
    return this.prescriptionsService.replenishStock(payload?.items);
  }

  @MessagePattern({ cmd: 'update_prescription_item' })
  updateItem(
    @Payload() payload: {
      id: string;
      dosagePerTime?: number;
      currentStock?: number;
      reorderThreshold?: number;
      instructions?: string | null;
    },
  ) {
    const { id, ...changes } = payload;
    return this.prescriptionsService.updateItem(id, changes);
  }
}
