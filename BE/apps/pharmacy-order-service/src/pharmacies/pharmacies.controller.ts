import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { PharmaciesService } from './pharmacies.service.js';

@Controller()
export class PharmaciesController {
  constructor(private readonly pharmaciesService: PharmaciesService) {}

  @MessagePattern({ cmd: 'create_pharmacy' })
  create(@Payload() payload: Parameters<PharmaciesService['create']>[0]) {
    return this.pharmaciesService.create(payload);
  }

  @MessagePattern({ cmd: 'list_pharmacies' })
  list(@Payload() payload: Parameters<PharmaciesService['list']>[0]) {
    return this.pharmaciesService.list(payload);
  }

  @MessagePattern({ cmd: 'get_pharmacy' })
  getById(@Payload() payload: { id: string }) {
    return this.pharmaciesService.getById(payload.id);
  }

  @MessagePattern({ cmd: 'update_pharmacy' })
  update(@Payload() payload: Parameters<PharmaciesService['update']>[1] & { id: string }) {
    const { id, ...changes } = payload;
    return this.pharmaciesService.update(id, changes);
  }

  @MessagePattern({ cmd: 'list_pharmacy_inventory' })
  listInventory(@Payload() payload: { pharmacyId: string }) {
    return this.pharmaciesService.listInventory(payload.pharmacyId);
  }

  @MessagePattern({ cmd: 'upsert_pharmacy_inventory' })
  upsertInventory(@Payload() payload: Parameters<PharmaciesService['upsertInventory']>[1] & { pharmacyId: string }) {
    const { pharmacyId, ...item } = payload;
    return this.pharmaciesService.upsertInventory(pharmacyId, item);
  }
}
