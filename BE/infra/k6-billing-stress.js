import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    surge: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 50 },
        { duration: '8m', target: 50 },
        { duration: '30s', target: 0 },
      ],
    },
  },
};

export default function () {
  const res = http.get(
    'http://meds-login-alb-1400872695.ap-southeast-1.elb.amazonaws.com/api/v1/billing/config',
  );
  check(res, { '200': (r) => r.status === 200 });
  sleep(0.2);
}
