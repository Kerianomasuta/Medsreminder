import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { AdminPaymentsService } from './admin-payments.service.js';
import { BillingService } from './billing.service.js';

@Controller()
export class BillingController {
  constructor(
    private readonly billingService: BillingService,
    private readonly adminPaymentsService: AdminPaymentsService,
  ) {}

  @MessagePattern({ cmd: 'admin_payment_summary' })
  adminSummary() {
    return this.adminPaymentsService.summary();
  }

  @MessagePattern({ cmd: 'admin_list_payments' })
  adminList(@Payload() payload: { status?: string; plan?: string; userId?: string; q?: string; from?: string; to?: string; page?: number; limit?: number }) {
    return this.adminPaymentsService.list(payload ?? {});
  }

  @MessagePattern({ cmd: 'admin_get_payment' })
  adminDetail(@Payload() payload: { paymentId?: string }) {
    return this.adminPaymentsService.detail(payload?.paymentId);
  }

  @MessagePattern({ cmd: 'handle_list_premium_plans' })
  plans() {
    return this.billingService.plans();
  }

  @MessagePattern({ cmd: 'handle_billing_config' })
  config() {
    return this.billingService.config();
  }

  @MessagePattern({ cmd: 'handle_create_payment_link' })
  createPaymentLink(@Payload() payload: { userId?: string; plan?: string; returnUrl?: string; cancelUrl?: string }) {
    return this.billingService.createPaymentLink(payload ?? {});
  }

  @MessagePattern({ cmd: 'handle_payos_webhook' })
  payosWebhook(@Payload() payload: { body?: unknown }) {
    return this.billingService.confirmPayos(payload?.body);
  }
}
