import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { escapeRegex, pageWindow, vietnamRange } from '@lib/admin-query';
import { ErrorHandling } from '@lib/error-handling';
import { Model, Types } from 'mongoose';
import { User, UserDocument } from '../users/schema/user.schema.js';
import { rollupPayments } from './admin-payments.js';
import { isPremiumPlan } from './premium-plan.js';
import { PremiumPayment, PremiumPaymentDocument } from './schema/premium-payment.schema.js';

const STATUSES = ['PENDING', 'PAID', 'FAILED'];

type ListInput = {
  status?: string;
  plan?: string;
  userId?: string;
  q?: string;
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
};

type PaymentRow = {
  _id?: unknown;
  userId?: string;
  plan?: string;
  amount?: number;
  txnRef?: string;
  orderCode?: number;
  status?: string;
  providerTransactionNo?: string;
  paidAt?: Date | null;
  createdAt?: Date | null;
  updatedAt?: Date | null;
};

type UserRow = {
  _id?: unknown;
  fullName?: string;
  email?: string;
  isPremium?: boolean;
  premiumExpiresAt?: Date | null;
};

@Injectable()
export class AdminPaymentsService {
  constructor(
    @InjectModel(PremiumPayment.name)
    private readonly payments: Model<PremiumPaymentDocument>,
    @InjectModel(User.name)
    private readonly users: Model<UserDocument>,
  ) {}

  async summary() {
    const now = Date.now();
    const [groups, paidLast7Days, paidLast30Days] = await Promise.all([
      this.payments.aggregate<{ _id: { status?: string; plan?: string }; count: number; amount: number }>([
        { $group: { _id: { status: '$status', plan: '$plan' }, count: { $sum: 1 }, amount: { $sum: '$amount' } } },
      ]),
      this.paidSince(new Date(now - 7 * 24 * 60 * 60 * 1000)),
      this.paidSince(new Date(now - 30 * 24 * 60 * 60 * 1000)),
    ]);
    return {
      ...rollupPayments(groups.map((group) => ({
        status: String(group._id?.status ?? ''),
        plan: String(group._id?.plan ?? ''),
        count: group.count,
        amount: group.amount,
      }))),
      paidLast7Days,
      paidLast30Days,
    };
  }

  async list(input: ListInput) {
    const window = pageWindow(input.page, input.limit);
    const filter = this.filter(input);
    const [total, rows] = await Promise.all([
      this.payments.countDocuments(filter),
      this.payments.find(filter).sort({ createdAt: -1 }).skip(window.skip).limit(window.limit).lean(),
    ]);
    const accounts = await this.accountMap(rows.map((row) => row.userId));
    return {
      page: window.page,
      limit: window.limit,
      total,
      payments: rows.map((row) => this.toPayment(row, accounts.get(row.userId))),
    };
  }

  async detail(paymentId?: string) {
    if (!paymentId || !Types.ObjectId.isValid(paymentId)) {
      throw ErrorHandling.BadRequest('Payment id is invalid');
    }
    const payment = await this.payments.findById(paymentId).lean();
    if (!payment) {
      throw ErrorHandling.NotFound('Payment not found');
    }
    const account = (await this.accountMap([payment.userId])).get(payment.userId);
    return { payment: this.toPayment(payment, account) };
  }

  private async paidSince(since: Date) {
    const [row] = await this.payments.aggregate<{ count: number; amount: number }>([
      { $match: { status: 'PAID', paidAt: { $gte: since } } },
      { $group: { _id: null, count: { $sum: 1 }, amount: { $sum: '$amount' } } },
    ]);
    return { count: row?.count ?? 0, amount: row?.amount ?? 0 };
  }

  private filter(input: ListInput) {
    const filter: Record<string, unknown> = {};
    if (input.status) {
      if (!STATUSES.includes(input.status)) {
        throw ErrorHandling.BadRequest('Payment status is not supported');
      }
      filter.status = input.status;
    }
    if (input.plan) {
      if (!isPremiumPlan(input.plan)) {
        throw ErrorHandling.BadRequest('Premium plan is not supported');
      }
      filter.plan = input.plan;
    }
    if (input.userId) {
      if (!/^[0-9a-f]{24}$/i.test(input.userId)) {
        throw ErrorHandling.BadRequest('User id is invalid');
      }
      filter.userId = input.userId;
    }
    const range = vietnamRange(input.from, input.to);
    if ('error' in range) {
      throw ErrorHandling.BadRequest(range.error);
    }
    if (range.from || range.toExclusive) {
      filter.createdAt = {
        ...(range.from ? { $gte: range.from } : {}),
        ...(range.toExclusive ? { $lt: range.toExclusive } : {}),
      };
    }
    const query = input.q?.trim();
    if (query) {
      const pattern = escapeRegex(query);
      filter.$or = [
        { txnRef: { $regex: pattern, $options: 'i' } },
        { providerTransactionNo: { $regex: pattern, $options: 'i' } },
      ];
    }
    return filter;
  }

  private async accountMap(userIds: Array<string | undefined>) {
    const ids = [...new Set(userIds.filter((id): id is string => typeof id === 'string' && Types.ObjectId.isValid(id)))];
    const accounts = new Map<string, UserRow>();
    if (ids.length === 0) {
      return accounts;
    }
    const rows = await this.users
      .find({ _id: { $in: ids } })
      .select('fullName email isPremium premiumExpiresAt')
      .lean();
    for (const row of rows) {
      accounts.set(String(row._id), row);
    }
    return accounts;
  }

  private toPayment(row: PaymentRow, account?: UserRow) {
    return {
      id: String(row._id ?? ''),
      userId: row.userId ?? '',
      user: account
        ? {
            id: String(account._id ?? row.userId ?? ''),
            fullName: account.fullName ?? '',
            email: account.email ?? '',
            isPremium: account.isPremium === true,
            premiumExpiresAt: account.premiumExpiresAt ?? null,
          }
        : null,
      plan: row.plan ?? '',
      amount: row.amount ?? 0,
      txnRef: row.txnRef ?? '',
      orderCode: row.orderCode ?? null,
      status: row.status ?? '',
      providerTransactionNo: row.providerTransactionNo ?? null,
      paidAt: row.paidAt ?? null,
      createdAt: row.createdAt ?? null,
      updatedAt: row.updatedAt ?? null,
    };
  }
}
