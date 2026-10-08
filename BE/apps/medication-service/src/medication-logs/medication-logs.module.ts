import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MedicationLogsController } from './medication-logs.controller.js';
import { MedicationLogsService } from './medication-logs.service.js';
import { MedicationLog } from './schema/medication-log.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([MedicationLog])],
  controllers: [MedicationLogsController],
  providers: [MedicationLogsService],
  exports: [TypeOrmModule],
})
export class MedicationLogsModule {}
