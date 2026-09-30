import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { ScheduleRulesService } from './schedule-rules.service.js';

type ScheduleMessage = {
  reminderTime?: string;
  daysOfWeek?: number[];
};

@Controller()
export class ScheduleRulesController {
  constructor(private readonly scheduleRulesService: ScheduleRulesService) {}

  @MessagePattern({ cmd: 'list_schedule_rules' })
  list(@Payload() payload: { patientId?: string; isActive?: boolean }) {
    return this.scheduleRulesService.list(payload?.patientId, payload?.isActive);
  }

  @MessagePattern({ cmd: 'get_schedule_rule' })
  getById(@Payload() payload: { id: string }) {
    return this.scheduleRulesService.getById(payload.id);
  }

  @MessagePattern({ cmd: 'create_schedule_rule' })
  create(@Payload() payload: ScheduleMessage & { prescriptionItemId?: string }) {
    const { prescriptionItemId, ...schedule } = payload;
    return this.scheduleRulesService.create(prescriptionItemId, schedule);
  }

  @MessagePattern({ cmd: 'update_schedule_rule' })
  update(
    @Payload() payload: ScheduleMessage & {
      id: string;
      isActive?: boolean;
    },
  ) {
    const { id, ...changes } = payload;
    return this.scheduleRulesService.update(id, changes);
  }
}
