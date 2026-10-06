import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { PharmaciesService } from './pharmacies.service.js';

<<<<<<< HEAD
=======
type PharmacyMessage = {
  pharmacistId?: string;
  name?: string;
  phone?: string;
  addressText?: string;
  latitude?: number;
  longitude?: number;
  isActive?: boolean;
};

>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
@Controller()
export class PharmaciesController {
  constructor(private readonly pharmaciesService: PharmaciesService) {}

  @MessagePattern({ cmd: 'create_pharmacy' })
<<<<<<< HEAD
  create(@Payload() payload: Parameters<PharmaciesService['create']>[0]) {
=======
  create(@Payload() payload: PharmacyMessage) {
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
    return this.pharmaciesService.create(payload);
  }

  @MessagePattern({ cmd: 'list_pharmacies' })
<<<<<<< HEAD
  list(@Payload() payload: Parameters<PharmaciesService['list']>[0]) {
    return this.pharmaciesService.list(payload);
=======
  list(@Payload() payload: { search?: string }) {
    return this.pharmaciesService.list(payload?.search);
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  }

  @MessagePattern({ cmd: 'get_pharmacy' })
  getById(@Payload() payload: { id: string }) {
    return this.pharmaciesService.getById(payload.id);
  }

  @MessagePattern({ cmd: 'update_pharmacy' })
<<<<<<< HEAD
  update(@Payload() payload: Parameters<PharmaciesService['update']>[1] & { id: string }) {
    const { id, ...changes } = payload;
    return this.pharmaciesService.update(id, changes);
  }

  @MessagePattern({ cmd: 'list_pharmacy_inventory' })
  listInventory(@Payload() payload: { pharmacyId: string }) {
    return this.pharmaciesService.listInventory(payload.pharmacyId);
  }

  @MessagePattern({ cmd: 'upsert_pharmacy_inventory' })
  upsertInventory(@Payload() payload: { pharmacyId: string; items: Parameters<PharmaciesService['upsertInventory']>[1] }) {
    return this.pharmaciesService.upsertInventory(payload.pharmacyId, payload.items);
  }
=======
  update(@Payload() payload: PharmacyMessage & { id: string }) {
    const { id, ...changes } = payload;
    return this.pharmaciesService.update(id, changes);
  }
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
}
