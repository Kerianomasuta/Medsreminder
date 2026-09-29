import { Module } from '@nestjs/common';
import { MedicationServiceController } from './medication-service.controller.js';
import { MedicationServiceService } from './medication-service.service.js';

@Module({
  imports: [],
  controllers: [MedicationServiceController],
  providers: [MedicationServiceService],
})
export class MedicationServiceModule {}
