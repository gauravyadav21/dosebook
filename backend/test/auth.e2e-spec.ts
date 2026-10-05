import type { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createApp, signUp } from './support/app.js';

describe('Auth and first-run acknowledgement (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('registers a user and returns a token that works', async () => {
    const user = await signUp(app);
    const me = await http().get('/me').set(user.auth).expect(200);
    expect(me.body.email).toBe(user.email);
  });

  it('stores the password hashed, never in plain text', async () => {
    const user = await signUp(app);
    const row = await app.get(PrismaService).user.findUniqueOrThrow({ where: { email: user.email } });
    expect(row.passwordHash).not.toContain(user.password);
    expect(row.passwordHash.startsWith('scrypt$')).toBe(true);
  });

  it('rejects a second account with the same email', async () => {
    const user = await signUp(app);
    await http().post('/auth/register').send({ email: user.email.toUpperCase(), password: 'another-password' }).expect(409);
  });

  it.each([
    [{ email: 'not-an-email', password: 'long-enough-password' }],
    [{ email: 'a@example.com', password: 'short' }],
    [{ email: 'a@example.com' }],
    [{ email: 'a@example.com', password: 'long-enough-password', role: 'admin' }],
  ])('rejects bad registration input %j', async (body) => {
    await http().post('/auth/register').send(body).expect(400);
  });

  it('logs in with the right password and refuses the wrong one', async () => {
    const user = await signUp(app);
    const ok = await http().post('/auth/login').send({ email: user.email, password: user.password }).expect(200);
    expect(ok.body.accessToken).toEqual(expect.any(String));
    await http().post('/auth/login').send({ email: user.email, password: 'wrong-password-here' }).expect(401);
  });

  it('gives the same answer for an unknown email as for a wrong password', async () => {
    const user = await signUp(app);
    const wrong = await http().post('/auth/login').send({ email: user.email, password: 'wrong-password-here' });
    const unknown = await http().post('/auth/login').send({ email: 'nobody@example.com', password: 'wrong-password-here' });
    expect(unknown.status).toBe(401);
    expect(unknown.body.message).toBe(wrong.body.message);
  });

  it('requires a token on protected routes', async () => {
    await http().get('/me').expect(401);
    await http().get('/prescriptions').expect(401);
    await http().post('/chat').send({ message: 'hello' }).expect(401);
  });

  it('refuses a malformed token', async () => {
    await http().get('/me').set({ Authorization: 'Bearer not.a.token' }).expect(401);
  });

  it('refuses an expired token', async () => {
    const user = await signUp(app);
    const row = await app.get(PrismaService).user.findUniqueOrThrow({ where: { email: user.email } });
    const expired = await app.get(JwtService).signAsync({ sub: row.id }, { expiresIn: -10 });
    await http().get('/me').set({ Authorization: `Bearer ${expired}` }).expect(401);
  });

  it('refuses a token whose account no longer exists', async () => {
    const user = await signUp(app);
    await app.get(PrismaService).user.delete({ where: { email: user.email } });
    await http().get('/me').set(user.auth).expect(401);
  });

  it('keeps health public', async () => {
    await http().get('/health').expect(200);
  });

  describe('first-run acknowledgement (S8)', () => {
    it('is required for a new user and stored once acknowledged', async () => {
      const user = await signUp(app);
      const before = await http().get('/me').set(user.auth).expect(200);
      expect(before.body.acknowledgement).toEqual({ currentVersion: 1, acknowledgedVersion: null, required: true });

      const after = await http().put('/me/acknowledgement').set(user.auth).send({ version: 1 }).expect(200);
      expect(after.body.acknowledgement.required).toBe(false);

      const again = await http().get('/me').set(user.auth).expect(200);
      expect(again.body.acknowledgement).toEqual({ currentVersion: 1, acknowledgedVersion: 1, required: false });
    });

    it('is required again when the stored version is older than the current wording', async () => {
      const user = await signUp(app);
      await app.get(PrismaService).user.update({ where: { email: user.email }, data: { ackVersion: 0 } });
      const me = await http().get('/me').set(user.auth).expect(200);
      expect(me.body.acknowledgement.required).toBe(true);
    });

    it('rejects acknowledging a version that is not the current one', async () => {
      const user = await signUp(app);
      await http().put('/me/acknowledgement').set(user.auth).send({ version: 99 }).expect(400);
      await http().put('/me/acknowledgement').set(user.auth).send({}).expect(400);
    });
  });
});
