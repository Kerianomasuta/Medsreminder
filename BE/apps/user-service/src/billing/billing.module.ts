import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { User, UserSchema } from '../users/schema/user.schema.js';
import { AdminPaymentsService } from './admin-payments.service.js';
import { BillingController } from './billing.controller.js';
import { BillingService } from './billing.service.js';
import { PremiumPayment, PremiumPaymentSchema } from './schema/premium-payment.schema.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: PremiumPayment.name, schema: PremiumPaymentSchema },
    ]),
  ],
  controllers: [BillingController],
  providers: [BillingService, AdminPaymentsService],
})
export class BillingModule {}
