import { describe, expect, it } from 'vitest';
import { rollupPayments } from './admin-payments.js';

describe('rollupPayments', () => {
  it('sums paid revenue by plan and keeps pending amounts separate', () => {
    expect(rollupPayments([
      { status: 'PAID', plan: 'MONTH', count: 2, amount: 98_000 },
      { status: 'PAID', plan: 'YEAR', count: 1, amount: 470_400 },
      { status: 'PENDING', plan: 'MONTH', count: 3, amount: 147_000 },
      { status: 'FAILED', plan: 'YEAR', count: 1, amount: 470_400 },
    ])).toEqual({
      total: 7,
      pending: 3,
      paid: 3,
      failed: 1,
      paidAmount: 568_400,
      pendingAmount: 147_000,
      month: { paid: 2, paidAmount: 98_000 },
      year: { paid: 1, paidAmount: 470_400 },
    });
  });
});
