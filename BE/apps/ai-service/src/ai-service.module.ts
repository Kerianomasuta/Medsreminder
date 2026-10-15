import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DrugInteractionModule } from './drug-interaction/drug-interaction.module.js';
import { PrescriptionScanModule } from './prescription-scan/prescription-scan.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/ai-service/.env',
    }),
    PrescriptionScanModule,
    DrugInteractionModule,
  ],
})
export class AiServiceModule {}
