import { Controller, Get } from '@nestjs/common';
import { MedicationServiceService } from './medication-service.service.js';

@Controller()
export class MedicationServiceController {
  constructor(private readonly medicationServiceService: MedicationServiceService) {}

  @Get()
  getHello(): string {
    return this.medicationServiceService.getHello();
  }
}
