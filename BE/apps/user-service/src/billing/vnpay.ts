import { createHmac, timingSafeEqual } from 'node:crypto';

const HASH_FIELDS = new Set(['vnp_SecureHash', 'vnp_SecureHashType']);

export function signVnpay(params: Record<string, string>, secret: string) {
  return createHmac('sha512', secret).update(signData(params), 'utf8').digest('hex');
}

export function verifyVnpay(params: Record<string, string>, secret: string) {
  const received = (params.vnp_SecureHash ?? '').toLowerCase();
  const expected = signVnpay(params, secret).toLowerCase();
  const receivedBytes = Buffer.from(received, 'utf8');
  const expectedBytes = Buffer.from(expected, 'utf8');
  return receivedBytes.length === expectedBytes.length && timingSafeEqual(receivedBytes, expectedBytes);
}

export function paymentUrl(endpoint: string, params: Record<string, string>, secret: string) {
  const hash = signVnpay(params, secret);
  return `${endpoint}?${signData(params)}&vnp_SecureHash=${hash}`;
}

export function signData(params: Record<string, string>) {
  return Object.keys(params)
    .filter((key) => !HASH_FIELDS.has(key) && params[key] !== '')
    .sort()
    .map((key) => `${encodeVnpay(key)}=${encodeVnpay(params[key])}`)
    .join('&');
}

function encodeVnpay(value: string) {
  return encodeURIComponent(value).replace(/%20/g, '+');
}
