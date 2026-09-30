import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { MedicinesService } from './medicines.service.js';

type MedicineMessage = {
  name?: string;
  genericName?: string | null;
  unit?: string;
  instructionNote?: string | null;
  imageUrl?: string | null;
};

@Controller()
export class MedicinesController {
  constructor(private readonly medicinesService: MedicinesService) {}

  @MessagePattern({ cmd: 'create_medicine' })
  create(@Payload() payload: MedicineMessage) {
    return this.medicinesService.create(payload);
  }

  @MessagePattern({ cmd: 'list_medicines' })
  list(@Payload() payload: { search?: string }) {
    return this.medicinesService.list(payload?.search);
  }

  @MessagePattern({ cmd: 'get_medicine' })
  getById(@Payload() payload: { id: string }) {
    return this.medicinesService.getById(payload.id);
  }

  @MessagePattern({ cmd: 'update_medicine' })
  update(@Payload() payload: MedicineMessage & { id: string }) {
    const { id, ...changes } = payload;
    return this.medicinesService.update(id, changes);
  }
}
