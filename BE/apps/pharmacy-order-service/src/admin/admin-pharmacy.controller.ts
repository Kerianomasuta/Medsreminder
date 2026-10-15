import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { AdminPharmacyService } from './admin-pharmacy.service.js';

type ListPayload = {
  q?: string;
  status?: string;
  pharmacyId?: string;
  patientId?: string;
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
};

@Controller()
export class AdminPharmacyController {
  constructor(private readonly adminPharmacyService: AdminPharmacyService) {}

  @MessagePattern({ cmd: 'admin_pharmacy_summary' })
  summary() {
    return this.adminPharmacyService.summary();
  }

  @MessagePattern({ cmd: 'admin_list_pharmacies' })
  listPharmacies(@Payload() payload: ListPayload) {
    return this.adminPharmacyService.listPharmacies(payload ?? {});
  }

  @MessagePattern({ cmd: 'admin_get_pharmacy' })
  pharmacy(@Payload() payload: { id?: string }) {
    return this.adminPharmacyService.pharmacyDetail(payload?.id);
  }

  @MessagePattern({ cmd: 'admin_list_orders' })
  listOrders(@Payload() payload: ListPayload) {
    return this.adminPharmacyService.listOrders(payload ?? {});
  }

  @MessagePattern({ cmd: 'admin_get_order' })
  order(@Payload() payload: { id?: string }) {
    return this.adminPharmacyService.orderDetail(payload?.id);
  }
}
