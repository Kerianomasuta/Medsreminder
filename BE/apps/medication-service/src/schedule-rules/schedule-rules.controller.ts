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
  list(@Payload() payload: { patientId?: string; isActive?: boolean; actorUserId?: string; actorRole?: string }) {
    return this.scheduleRulesService.list(payload?.patientId, payload?.isActive, this.actor(payload));
  }

  @MessagePattern({ cmd: 'get_schedule_rule' })
  getById(@Payload() payload: { id: string; actorUserId?: string; actorRole?: string }) {
    return this.scheduleRulesService.getById(payload.id, this.actor(payload));
  }

  @MessagePattern({ cmd: 'create_schedule_rule' })
  create(@Payload() payload: ScheduleMessage & { prescriptionItemId?: string; actorUserId?: string; actorRole?: string }) {
    const { prescriptionItemId, actorUserId, actorRole, ...schedule } = payload;
    return this.scheduleRulesService.create(prescriptionItemId, schedule, { userId: actorUserId, role: actorRole });
  }

  @MessagePattern({ cmd: 'update_schedule_rule' })
  update(
    @Payload() payload: ScheduleMessage & {
      id: string;
      isActive?: boolean;
      actorUserId?: string;
      actorRole?: string;
    },
  ) {
    const { id, actorUserId, actorRole, ...changes } = payload;
    return this.scheduleRulesService.update(id, changes, { userId: actorUserId, role: actorRole });
  }

  private actor(payload?: { actorUserId?: string; actorRole?: string }) {
    if (!payload?.actorRole) {
      return undefined;
    }
    return { userId: payload.actorUserId, role: payload.actorRole };
  }
}
