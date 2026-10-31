import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import { Rate } from 'k6/metrics';

const BASE_URL = (__ENV.BASE_URL || 'https://medsreminder.duckdns.org').replace(
  /\/$/,
  '',
);
const PASSWORD = __ENV.STRESS_PASSWORD || 'StressTest9';
const USER_COUNT = Number(__ENV.STRESS_USERS || 200);
const TARGET_VUS = Number(__ENV.STRESS_VUS || 2000);
const RAMP = __ENV.STRESS_RAMP || '2m';
const HOLD = __ENV.STRESS_HOLD || '3m';
const loginFail = new Rate('login_fail');

const users = new SharedArray('stress-users', () =>
  Array.from({ length: USER_COUNT }, (_, i) => ({
    email: `stress${i + 1}@medsreminder.test`,
    password: PASSWORD,
    fullName: `Stress User ${i + 1}`,
    phone: `09${String(10000000 + i).slice(-8)}`,
  })),
);

export const options = {
  setupTimeout: '5m',
  scenarios: {
    login_surge: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: RAMP, target: TARGET_VUS },
        { duration: HOLD, target: TARGET_VUS },
        { duration: '30s', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<8000'],
    login_fail: ['rate<0.05'],
  },
};

export function setup() {
  const seeded = [];
  for (const user of users) {
    const register = http.post(
      `${BASE_URL}/api/v1/auth/register`,
      JSON.stringify({
        email: user.email,
        password: user.password,
        fullName: user.fullName,
        phone: user.phone,
        role: 'PATIENT',
      }),
      { headers: { 'Content-Type': 'application/json' } },
    );
    if (register.status === 201 || register.status === 409 || register.status === 400) {
      seeded.push(user.email);
    }
  }
  return { seeded: seeded.length };
}

export default function () {
  const user = users[(__VU - 1) % users.length];
  const res = http.post(
    `${BASE_URL}/api/v1/auth/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: { 'Content-Type': 'application/json' }, timeout: '20s' },
  );
  const ok = check(res, {
    'login ok': (r) => r.status === 200 || r.status === 201,
  });
  loginFail.add(!ok);
  sleep(1);
}
