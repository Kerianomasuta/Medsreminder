import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'
import { AdminModule } from './admin/admin.module.js';
import { AuthModule } from './auth/auth.module.js';
import { BillingModule } from './billing/billing.module.js';
import { MedicationLogsModule } from './medication-logs/medication-logs.module.js';
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

    AdminModule,
    AuthModule,
    BillingModule,
    MedicationLogsModule,
    PrescriptionsModule,
    ScheduleRulesModule,
    UserModule,
    PharmaciesModule,
    OrdersModule,
  ],
})
export class ApiGatewayModule {}
