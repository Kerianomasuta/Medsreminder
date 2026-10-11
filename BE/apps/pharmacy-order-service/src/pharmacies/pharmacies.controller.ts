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
}
