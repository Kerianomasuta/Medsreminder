import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { DrugInteractionService } from './drug-interaction.service.js';

@Controller()
export class DrugInteractionController {
  constructor(private readonly drugInteractionService: DrugInteractionService) {}

  @MessagePattern({ cmd: 'check_drug_interaction' })
  check(@Payload() payload: { currentNames?: unknown; newNames?: unknown } | undefined) {
    return this.drugInteractionService.check(payload);
  }
}
