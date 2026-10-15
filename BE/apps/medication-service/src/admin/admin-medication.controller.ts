import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { AdminMedicationService } from './admin-medication.service.js';

type ListPayload = {
  patientId?: string;
  isActive?: boolean;
  status?: string;
  q?: string;
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
};

@Controller()
export class AdminMedicationController {
  constructor(private readonly adminMedicationService: AdminMedicationService) {}

  @MessagePattern({ cmd: 'admin_medication_summary' })
  summary() {
    return this.adminMedicationService.summary();
  }

  @MessagePattern({ cmd: 'admin_list_prescriptions' })
  listPrescriptions(@Payload() payload: ListPayload) {
    return this.adminMedicationService.listPrescriptions(payload ?? {});
  }

  @MessagePattern({ cmd: 'admin_get_prescription' })
  prescription(@Payload() payload: { id?: string }) {
    return this.adminMedicationService.prescriptionDetail(payload?.id);
  }

  @MessagePattern({ cmd: 'admin_list_medication_logs' })
  listLogs(@Payload() payload: ListPayload) {
    return this.adminMedicationService.listLogs(payload ?? {});
  }
}
