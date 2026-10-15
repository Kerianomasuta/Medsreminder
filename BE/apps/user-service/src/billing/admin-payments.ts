export type PaymentGroup = {
  status: string;
  plan: string;
  count: number;
  amount: number;
};

export function rollupPayments(groups: PaymentGroup[]) {
  const summary = {
    total: 0,
    pending: 0,
    paid: 0,
    failed: 0,
    paidAmount: 0,
    pendingAmount: 0,
    month: { paid: 0, paidAmount: 0 },
    year: { paid: 0, paidAmount: 0 },
  };
  for (const group of groups) {
    const count = Number.isFinite(group.count) ? group.count : 0;
    const amount = Number.isFinite(group.amount) ? group.amount : 0;
    summary.total += count;
    if (group.status === 'PENDING') {
      summary.pending += count;
      summary.pendingAmount += amount;
    }
    if (group.status === 'FAILED') {
      summary.failed += count;
    }
    if (group.status !== 'PAID') {
      continue;
    }
    summary.paid += count;
    summary.paidAmount += amount;
    if (group.plan === 'MONTH') {
      summary.month.paid += count;
      summary.month.paidAmount += amount;
    }
    if (group.plan === 'YEAR') {
      summary.year.paid += count;
      summary.year.paidAmount += amount;
    }
  }
  return summary;
}
