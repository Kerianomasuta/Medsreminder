import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { DoseActionInput, ListLogsInput, MedicationLogsService } from './medication-logs.service.js';

@Controller()
export class MedicationLogsController {
  constructor(private readonly medicationLogsService: MedicationLogsService) {}

  @MessagePattern({ cmd: 'list_medication_logs' })
  list(@Payload() payload: ListLogsInput) {
    return this.medicationLogsService.list(payload);
  }

  @MessagePattern({ cmd: 'take_medication_log' })
  take(@Payload() payload: DoseActionInput & { id: string }) {
    const { id, ...action } = payload;
    return this.medicationLogsService.take(id, action);
  }

  @MessagePattern({ cmd: 'snooze_medication_log' })
  snooze(@Payload() payload: DoseActionInput & { id: string }) {
    const { id, ...action } = payload;
    return this.medicationLogsService.snooze(id, action);
  }

  @MessagePattern({ cmd: 'skip_medication_log' })
  skip(@Payload() payload: DoseActionInput & { id: string }) {
    const { id, ...action } = payload;
    return this.medicationLogsService.skip(id, action);
  }

  @MessagePattern({ cmd: 'miss_medication_log' })
  miss(@Payload() payload: DoseActionInput & { id: string }) {
    const { id, ...action } = payload;
    return this.medicationLogsService.miss(id, action);
  }
}
