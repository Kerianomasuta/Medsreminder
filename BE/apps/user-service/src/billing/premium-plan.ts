export const PREMIUM_PLANS = {
  MONTH: 49_000,
  YEAR: 49_000 * 12 * 80 / 100,
} as const;

export type PremiumPlan = keyof typeof PREMIUM_PLANS;

export function isPremiumPlan(value: string | undefined): value is PremiumPlan {
  return value === 'MONTH' || value === 'YEAR';
}

export function premiumPrice(plan: PremiumPlan) {
  return PREMIUM_PLANS[plan];
}

export function payosDescription(plan: PremiumPlan) {
  return plan === 'YEAR' ? 'MedsReminder VIP 1 nam' : 'MedsReminder VIP';
}

export function nextOrderCode(now = Date.now(), digit = Math.floor(Math.random() * 10)) {
  return now * 10 + (Math.abs(digit) % 10);
}

export function extendPremium(currentExpiry: Date | null, plan: PremiumPlan, now: Date) {
  const base = currentExpiry && currentExpiry.getTime() > now.getTime()
    ? new Date(currentExpiry)
    : new Date(now);
  return plan === 'MONTH' ? addUtcMonths(base, 1) : addUtcYears(base, 1);
}

function addUtcMonths(date: Date, months: number) {
  const day = date.getUTCDate();
  const result = new Date(date);
  result.setUTCDate(1);
  result.setUTCMonth(result.getUTCMonth() + months);
  const lastDay = new Date(Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0)).getUTCDate();
  result.setUTCDate(Math.min(day, lastDay));
  return result;
}

function addUtcYears(date: Date, years: number) {
  return addUtcMonths(date, years * 12);
}
