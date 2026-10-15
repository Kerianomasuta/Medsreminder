import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ErrorHandling } from '@lib/error-handling';
import { User, UserDocument } from '../users/schema/user.schema.js';
import { PayOS, type Webhook } from '@payos/node';
import { extendPremium, isPremiumPlan, monthPlanStillActive, nextOrderCode, payosDescription, premiumPrice, type PremiumPlan } from './premium-plan.js';
import { PremiumPayment, PremiumPaymentDocument } from './schema/premium-payment.schema.js';

@Injectable()
export class BillingService {
  constructor(
    private readonly configService: ConfigService,
    @InjectModel(User.name)
    private readonly users: Model<UserDocument>,
    @InjectModel(PremiumPayment.name)
    private readonly payments: Model<PremiumPaymentDocument>,
  ) {}

  plans() {
    return {
      plans: [
        { plan: 'MONTH' as const, amount: premiumPrice('MONTH'), label: '1 tháng' },
        { plan: 'YEAR' as const, amount: premiumPrice('YEAR'), label: '1 năm, giảm 20%' },
      ],
    };
  }

  config() {
    return { is_payment_enabled: this.paymentEnabled() };
  }

  async createPaymentLink(input: { userId?: string; plan?: string }) {
    if (!this.paymentEnabled()) {
      throw ErrorHandling.Forbidden('Tính năng thanh toán đang bảo trì');
    }
    if (!input.userId) {
      throw ErrorHandling.AuthenticationFailed('User is unauthenticated');
    }
    if (!isPremiumPlan(input.plan)) {
      throw ErrorHandling.BadRequest('plan must be MONTH or YEAR');
    }
    const user = await this.users.findById(input.userId).select('_id premiumExpiresAt').exec();
    if (!user) {
      throw ErrorHandling.NotFound('User not found');
    }
    await this.assertMonthPlanOpen(input.userId, user.premiumExpiresAt ?? null);

    const plan: PremiumPlan = input.plan;
    const amount = premiumPrice(plan);
    const description = payosDescription(plan);
    const orderCode = nextOrderCode();
    await this.payments.create({
      userId: input.userId,
      plan,
      amount,
      txnRef: String(orderCode),
      orderCode,
      status: 'PENDING',
    });

    try {
      const link = await this.payos().paymentRequests.create({
        orderCode,
        amount,
        description,
        returnUrl: this.payosUrl('PAYOS_RETURN_URL', 'medsreminder://payment-return'),
        cancelUrl: this.payosUrl('PAYOS_CANCEL_URL', 'medsreminder://payment-cancel'),
        items: [{ name: description, quantity: 1, price: amount }],
      });
      return { checkoutUrl: link.checkoutUrl, orderCode };
    } catch {
      await this.payments.updateOne({ orderCode, status: 'PENDING' }, { status: 'FAILED' }).exec();
      throw ErrorHandling.BadRequest('Không tạo được link thanh toán');
    }
  }

  async confirmPayos(body: unknown) {
    const webhook = asPayosWebhook(body);
    if (!webhook) {
      return { success: true };
    }
    let data;
    try {
      data = await this.payos().webhooks.verify(webhook);
    } catch {
      return { success: true };
    }

    const payment = await this.payments.findOne({ orderCode: data.orderCode }).exec();
    if (!payment) {
      return { success: true };
    }
    if (data.amount !== payment.amount) {
      return { success: true };
    }
    const paid = webhook.success !== false && data.code === '00';
    if (!paid) {
      await this.payments.updateOne({ orderCode: data.orderCode, status: 'PENDING' }, { status: 'FAILED' }).exec();
      return { success: true };
    }
    if (payment.status !== 'PENDING') {
      return { success: true };
    }

    const updated = await this.payments.findOneAndUpdate(
      { orderCode: data.orderCode, status: 'PENDING' },
      { status: 'PAID', paidAt: new Date(), providerTransactionNo: data.reference },
      { new: true },
    ).exec();
    if (!updated) {
      return { success: true };
    }
    await this.activate(updated.userId, updated.plan);
    return { success: true };
  }

  private async assertMonthPlanOpen(userId: string, expiresAt: Date | null) {
    const latestPaid = await this.payments
      .findOne({ userId, status: 'PAID' })
      .sort({ paidAt: -1, createdAt: -1 })
      .select('plan')
      .exec();
    if (monthPlanStillActive(latestPaid?.plan ?? null, expiresAt, new Date())) {
      throw ErrorHandling.Conflict('Gói VIP 1 tháng vẫn còn hạn. Không thể mua thêm gói cho đến khi hết hạn.');
    }
  }

  private async activate(userId: string, plan: PremiumPlan) {
    const user = await this.users.findById(userId).exec();
    if (!user) {
      throw ErrorHandling.NotFound('User not found');
    }
    const premiumExpiresAt = extendPremium(user.premiumExpiresAt ?? null, plan, new Date());
    user.isPremium = true;
    user.premiumExpiresAt = premiumExpiresAt;
    await user.save();
    return premiumExpiresAt;
  }

  private payosClient?: PayOS;

  private paymentEnabled() {
    const value = this.configService.get<string>('PAYMENT_ENABLED')?.trim().toLowerCase();
    return value === 'true' || value === '1';
  }

  private payos() {
    if (!this.payosClient) {
      this.payosClient = new PayOS({
        clientId: this.requiredConfig('PAYOS_CLIENT_ID'),
        apiKey: this.requiredConfig('PAYOS_API_KEY'),
        checksumKey: this.requiredConfig('PAYOS_CHECKSUM_KEY'),
      });
    }
    return this.payosClient;
  }

  private payosUrl(name: string, fallback: string) {
    return this.configService.get<string>(name)?.trim() || fallback;
  }

  private requiredConfig(name: string) {
    const value = this.configService.get<string>(name)?.trim();
    if (!value) {
      throw ErrorHandling.BadRequest(`${name} is not set`);
    }
    return value;
  }
}

function asPayosWebhook(body: unknown): Webhook | undefined {
  if (!body || typeof body !== 'object') {
    return undefined;
  }
  const value = body as Partial<Webhook>;
  if (typeof value.signature !== 'string' || !value.data || typeof value.data !== 'object') {
    return undefined;
  }
  return {
    code: typeof value.code === 'string' ? value.code : '00',
    desc: typeof value.desc === 'string' ? value.desc : '',
    success: value.success !== false,
    data: value.data,
    signature: value.signature,
  };
}
