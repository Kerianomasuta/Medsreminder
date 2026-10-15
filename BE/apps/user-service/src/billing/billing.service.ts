import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ErrorHandling } from '@lib/error-handling';
import { User, UserDocument } from '../users/schema/user.schema.js';
import { PayOS, type Webhook } from '@payos/node';
import { extendPremium, isPremiumPlan, nextOrderCode, payosDescription, premiumPrice, type PremiumPlan } from './premium-plan.js';
import { PremiumPayment, PremiumPaymentDocument } from './schema/premium-payment.schema.js';
import { paymentUrl, verifyVnpay } from './vnpay.js';

const PAYMENT_MINUTES = 15;

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
    const user = await this.users.findById(input.userId).select('_id').exec();
    if (!user) {
      throw ErrorHandling.NotFound('User not found');
    }

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
    if (!isPayosWebhook(body)) {
      throw ErrorHandling.BadRequest('Invalid webhook');
    }
    let data;
    try {
      data = await this.payos().webhooks.verify(body);
    } catch {
      throw ErrorHandling.BadRequest('Invalid signature');
    }

    const payment = await this.payments.findOne({ orderCode: data.orderCode }).exec();
    if (!payment) {
      return { success: true };
    }
    if (data.amount !== payment.amount) {
      return { success: true };
    }
    const paid = body.success === true && data.code === '00';
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

  async checkout(input: { userId?: string; plan?: string; ipAddr?: string }) {
    if (!input.userId) {
      throw ErrorHandling.AuthenticationFailed('User is unauthenticated');
    }
    if (!isPremiumPlan(input.plan)) {
      throw ErrorHandling.BadRequest('plan must be MONTH or YEAR');
    }
    const user = await this.users.findById(input.userId).select('_id').exec();
    if (!user) {
      throw ErrorHandling.NotFound('User not found');
    }

    const plan: PremiumPlan = input.plan;
    const amount = premiumPrice(plan);
    const txnRef = `PR${Date.now()}${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`;
    await this.payments.create({ userId: input.userId, plan, amount, txnRef, status: 'PENDING' });

    const createdAt = new Date();
    const params = {
      vnp_Version: '2.1.0',
      vnp_Command: 'pay',
      vnp_TmnCode: this.requiredConfig('VNPAY_TMN_CODE'),
      vnp_Amount: String(amount * 100),
      vnp_CurrCode: 'VND',
      vnp_TxnRef: txnRef,
      vnp_OrderInfo: `MedsReminder Premium ${plan}`,
      vnp_OrderType: 'other',
      vnp_Locale: 'vn',
      vnp_ReturnUrl: this.publicUrl('/api/v1/billing/vnpay/return'),
      vnp_IpnUrl: this.publicUrl('/api/v1/billing/vnpay/ipn'),
      vnp_IpAddr: normalizeIp(input.ipAddr),
      vnp_CreateDate: formatVnpayDate(createdAt),
      vnp_ExpireDate: formatVnpayDate(new Date(createdAt.getTime() + PAYMENT_MINUTES * 60_000)),
    };

    return {
      txnRef,
      plan,
      amount,
      paymentUrl: paymentUrl(this.paymentEndpoint(), params, this.requiredConfig('VNPAY_HASH_SECRET')),
    };
  }

  async confirm(query: Record<string, string>) {
    if (!verifyVnpay(query, this.requiredConfig('VNPAY_HASH_SECRET'))) {
      return { RspCode: '97', Message: 'Invalid signature' };
    }

    const payment = await this.payments.findOne({ txnRef: query.vnp_TxnRef }).exec();
    if (!payment) {
      return { RspCode: '01', Message: 'Order not found' };
    }
    if (Number(query.vnp_Amount) !== payment.amount * 100) {
      return { RspCode: '04', Message: 'Invalid amount' };
    }
    if (payment.status !== 'PENDING') {
      return { RspCode: '02', Message: 'Order already confirmed' };
    }

    const paid = query.vnp_ResponseCode === '00' && query.vnp_TransactionStatus === '00';
    if (!paid) {
      await this.payments.updateOne({ txnRef: payment.txnRef, status: 'PENDING' }, { status: 'FAILED' }).exec();
      return { RspCode: '00', Message: 'Confirm Success', paid: false };
    }

    const updated = await this.payments.findOneAndUpdate(
      { txnRef: payment.txnRef, status: 'PENDING' },
      {
        status: 'PAID',
        paidAt: new Date(),
        providerTransactionNo: query.vnp_TransactionNo,
      },
      { new: true },
    ).exec();
    if (!updated) {
      return { RspCode: '02', Message: 'Order already confirmed' };
    }

    const premiumExpiresAt = await this.activate(updated.userId, updated.plan);
    return { RspCode: '00', Message: 'Confirm Success', paid: true, plan: updated.plan, premiumExpiresAt };
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

  private paymentEndpoint() {
    return this.configService.get<string>('VNPAY_PAYMENT_URL')?.trim()
      || 'https://pay.vnpayment.vn/paymentv2/vpcpay.html';
  }

  private publicUrl(path: string) {
    const base = this.requiredConfig('PUBLIC_API_BASE_URL').replace(/\/$/, '');
    let url: URL;
    try {
      url = new URL(base);
    } catch {
      throw ErrorHandling.BadRequest('PUBLIC_API_BASE_URL must be a public https address');
    }
    const local = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
    if (url.protocol !== 'https:' || local) {
      throw ErrorHandling.BadRequest('PUBLIC_API_BASE_URL must be a public https address');
    }
    return `${base}${path}`;
  }

  private requiredConfig(name: string) {
    const value = this.configService.get<string>(name)?.trim();
    if (!value) {
      throw ErrorHandling.BadRequest(`${name} is not set`);
    }
    return value;
  }
}

function isPayosWebhook(body: unknown): body is Webhook {
  if (!body || typeof body !== 'object') {
    return false;
  }
  const value = body as Partial<Webhook>;
  return typeof value.signature === 'string'
    && typeof value.code === 'string'
    && typeof value.success === 'boolean'
    && !!value.data
    && typeof value.data === 'object';
}

function normalizeIp(ipAddr: string | undefined) {
  const ip = ipAddr?.split(',')[0]?.trim();
  if (!ip || ip === '::1' || ip.startsWith('::ffff:')) {
    return ip?.startsWith('::ffff:') ? ip.slice('::ffff:'.length) : '127.0.0.1';
  }
  return ip;
}

function formatVnpayDate(date: Date) {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);
  const read = (type: Intl.DateTimeFormatPartTypes) => parts.find((part) => part.type === type)?.value ?? '';
  return `${read('year')}${read('month')}${read('day')}${read('hour')}${read('minute')}${read('second')}`;
}
