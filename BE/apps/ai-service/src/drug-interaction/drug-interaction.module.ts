import { Module } from '@nestjs/common';
import { DrugInteractionController } from './drug-interaction.controller.js';
import { DrugInteractionService } from './drug-interaction.service.js';

@Module({
  controllers: [DrugInteractionController],
  providers: [DrugInteractionService],
})
export class DrugInteractionModule {}
