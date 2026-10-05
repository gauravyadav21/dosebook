import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createApp } from './support/app.js';

describe('Rate limit on sign-in (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    process.env.AUTH_THROTTLE_LIMIT = '3';
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('blocks repeated login attempts past the limit', async () => {
    const attempt = () =>
      request(app.getHttpServer()).post('/auth/login').send({ email: 'nobody@example.com', password: 'wrong-password-here' });
    for (let i = 0; i < 3; i++) {
      expect((await attempt()).status).toBe(401);
    }
    expect((await attempt()).status).toBe(429);
  });
});
