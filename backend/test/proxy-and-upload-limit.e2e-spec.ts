import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createApp, signUp, upload } from './support/app.js';

describe('S13 behind a hosting proxy (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    process.env.TRUST_PROXY = 'true';
    process.env.AUTH_THROTTLE_LIMIT = '2';
    process.env.UPLOAD_THROTTLE_LIMIT = '2';
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
    delete process.env.TRUST_PROXY;
  });

  const attempt = (address: string) =>
    request(app.getHttpServer())
      .post('/auth/login')
      .set('X-Forwarded-For', address)
      .send({ email: 'nobody@example.com', password: 'wrong-password-here' });

  it('counts sign-in attempts per visitor address, not once for everyone behind the proxy', async () => {
    expect((await attempt('203.0.113.1')).status).toBe(401);
    expect((await attempt('203.0.113.1')).status).toBe(401);
    expect((await attempt('203.0.113.1')).status).toBe(429);
    // A different visitor is not locked out by the first one.
    expect((await attempt('203.0.113.2')).status).toBe(401);
  });

  it('limits uploads on their own, since each one may spend model quota', async () => {
    const user = await signUp(app);
    expect((await upload(app, user)).status).toBe(201);
    expect((await upload(app, user)).status).toBe(201);
    expect((await upload(app, user)).status).toBe(429);
  });
});
