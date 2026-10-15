import { describe, expect, it } from 'vitest';
import { extendPremium, nextOrderCode, payosDescription, premiumPrice } from './premium-plan.js';
import { paymentUrl, verifyVnpay } from './vnpay.js';

describe('premium pricing', () => {
  it('charges 49000 for a month and 20 percent off a year', () => {
    expect(premiumPrice('MONTH')).toBe(49_000);
    expect(premiumPrice('YEAR')).toBe(470_400);
    expect(payosDescription('MONTH').length).toBeLessThanOrEqual(25);
    expect(payosDescription('YEAR').length).toBeLessThanOrEqual(25);
  });

  it('builds a PayOS order code that fits a safe integer', () => {
    const code = nextOrderCode(1_700_000_000_000, 7);
    expect(code).toBe(17_000_000_000_007);
    expect(Number.isSafeInteger(code)).toBe(true);
  });

  it('starts a new month from now when the current premium has expired', () => {
    const now = new Date('2026-10-15T03:00:00.000Z');
    const expiry = extendPremium(new Date('2026-10-01T03:00:00.000Z'), 'MONTH', now);
    expect(expiry.toISOString()).toBe('2026-11-15T03:00:00.000Z');
  });

  it('extends a year from the current expiry when it is still active', () => {
    const now = new Date('2026-10-15T03:00:00.000Z');
    const expiry = extendPremium(new Date('2026-12-01T03:00:00.000Z'), 'YEAR', now);
    expect(expiry.toISOString()).toBe('2027-12-01T03:00:00.000Z');
  });
});

describe('vnpay signature', () => {
  it('accepts the query string that was signed and rejects a changed amount', () => {
    const secret = 'TESTSECRET';
    const params = {
      vnp_Amount: '4900000',
      vnp_TxnRef: 'PR1',
      vnp_OrderInfo: 'MedsReminder Premium MONTH',
    };
    const url = new URL(paymentUrl('https://sandbox.vnpayment.vn/paymentv2/vpcpay.html', params, secret));
    const query = Object.fromEntries(url.searchParams.entries());

    expect(verifyVnpay(query, secret)).toBe(true);
    expect(verifyVnpay({ ...query, vnp_Amount: '100' }, secret)).toBe(false);
  });
});
