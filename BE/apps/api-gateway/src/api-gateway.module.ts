import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'
import { AuthModule } from './auth/auth.module.js';
import { MedicinesModule } from './medicines/medicines.module.js';
import { PrescriptionsModule } from './prescriptions/prescriptions.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/api-gateway/.env'
    }),

    AuthModule,
    MedicinesModule,
    PrescriptionsModule,
  ],
})
export class ApiGatewayModule {}
