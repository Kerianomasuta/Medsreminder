import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { PharmaciesService } from './pharmacies.service.js';

type PharmacyMessage = {
  pharmacistId?: string;
  name?: string;
  phone?: string;
  addressText?: string;
  latitude?: number;
  longitude?: number;
  isActive?: boolean;
};

@Controller()
export class PharmaciesController {
  constructor(private readonly pharmaciesService: PharmaciesService) {}

  @MessagePattern({ cmd: 'create_pharmacy' })
  create(@Payload() payload: PharmacyMessage) {
    return this.pharmaciesService.create(payload);
  }

  @MessagePattern({ cmd: 'list_pharmacies' })
  list(@Payload() payload: { search?: string }) {
    return this.pharmaciesService.list(payload?.search);
  }

  @MessagePattern({ cmd: 'get_pharmacy' })
  getById(@Payload() payload: { id: string }) {
    return this.pharmaciesService.getById(payload.id);
  }

  @MessagePattern({ cmd: 'update_pharmacy' })
  update(@Payload() payload: PharmacyMessage & { id: string }) {
    const { id, ...changes } = payload;
    return this.pharmaciesService.update(id, changes);
  }
}
