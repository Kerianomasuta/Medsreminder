import { afterAll, beforeAll, describe, it } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { ApiGatewayModule } from './../src/api-gateway.module.js';

// Integration test: boot the full API gateway (routing + guards + DI wiring)
// and verify a protected route is actually guarded. No external DB is needed
// because the gateway only proxies to services over TCP (connected lazily).
describe('ApiGateway (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [ApiGatewayModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('rejects a protected route without an access token (401)', () => {
    return request(app.getHttpServer())
      .get('/api/v1/users/profile')
      .expect(401);
  });
});
