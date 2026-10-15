import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { BillingService } from './billing.service.js';

@Controller()
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  @MessagePattern({ cmd: 'handle_list_premium_plans' })
  plans() {
    return this.billingService.plans();
  }

  @MessagePattern({ cmd: 'handle_billing_config' })
  config() {
    return this.billingService.config();
  }

  @MessagePattern({ cmd: 'handle_create_payment_link' })
  createPaymentLink(@Payload() payload: { userId?: string; plan?: string }) {
    return this.billingService.createPaymentLink(payload ?? {});
  }

  @MessagePattern({ cmd: 'handle_payos_webhook' })
  payosWebhook(@Payload() payload: { body?: unknown }) {
    return this.billingService.confirmPayos(payload?.body);
  }
}
