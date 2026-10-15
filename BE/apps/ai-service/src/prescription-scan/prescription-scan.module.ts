import { Module } from '@nestjs/common';
import { PrescriptionScanController } from './prescription-scan.controller.js';
import { PrescriptionScanService } from './prescription-scan.service.js';

@Module({
  controllers: [PrescriptionScanController],
  providers: [PrescriptionScanService],
})
export class PrescriptionScanModule {}
