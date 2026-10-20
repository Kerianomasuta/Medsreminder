import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { PrescriptionScanService } from './prescription-scan.service.js';

@Controller()
export class PrescriptionScanController {
  constructor(private readonly prescriptionScanService: PrescriptionScanService) {}

  @MessagePattern({ cmd: 'scan_prescription' })
  scan(@Payload() payload: { imageBase64?: string; mimeType?: string }) {
    return this.prescriptionScanService.scan(payload);
  }
}
