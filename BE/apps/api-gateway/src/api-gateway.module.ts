import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'
import { AuthModule } from './auth/auth.module.js';
import { MedicinesModule } from './medicines/medicines.module.js';
import { OrdersModule } from './orders/orders.module.js';
import { PharmaciesModule } from './pharmacies/pharmacies.module.js';
import { PrescriptionsModule } from './prescriptions/prescriptions.module.js';
import { ScheduleRulesModule } from './schedule-rules/schedule-rules.module.js';
import { UserModule } from './users/user.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/api-gateway/.env'
    }),

    AuthModule,
    MedicinesModule,
    PrescriptionsModule,
    ScheduleRulesModule,
    UserModule,
    PharmaciesModule,
    OrdersModule,
  ],
})
export class ApiGatewayModule {}
