import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { InventoryService } from './inventory.service.js';

type InventoryMessage = {
  medicineId?: string;
  stockQuantity?: number;
  pricePerUnit?: number;
};

@Controller()
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @MessagePattern({ cmd: 'list_pharmacy_inventory' })
  list(@Payload() payload: { pharmacyId?: string }) {
    return this.inventoryService.list(payload?.pharmacyId);
  }

  @MessagePattern({ cmd: 'add_pharmacy_inventory' })
  add(@Payload() payload: InventoryMessage & { pharmacyId?: string }) {
    const { pharmacyId, ...item } = payload;
    return this.inventoryService.add(pharmacyId, item);
  }

  @MessagePattern({ cmd: 'update_pharmacy_inventory' })
  update(@Payload() payload: InventoryMessage & { id: string }) {
    const { id, ...changes } = payload;
    return this.inventoryService.update(id, changes);
  }
}
