import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createApp, signUp } from './support/app.js';

const full = {
  name: 'Demo Patient',
  dateOfBirth: '1990-05-17',
  sex: 'FEMALE',
  heightCm: 165.5,
  weightKg: 62,
  bloodGroup: 'O+',
  emergencyName: 'Demo Contact',
  emergencyPhone: '+91 00000 00900',
  conditions: 'Asthma',
};

describe('S10 profile (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('starts empty for a new user', async () => {
    const user = await signUp(app);
    const res = await http().get('/me/profile').set(user.auth).expect(200);
    expect(res.body).toEqual({
      email: user.email,
      name: null,
      dateOfBirth: null,
      sex: null,
      heightCm: null,
      weightKg: null,
      bloodGroup: null,
      emergencyName: null,
      emergencyPhone: null,
      conditions: null,
    });
  });

  it('saves and returns every field', async () => {
    const user = await signUp(app);
    const saved = await http().put('/me/profile').set(user.auth).send(full).expect(200);
    expect(saved.body).toEqual({ email: user.email, ...full });
    expect((await http().get('/me/profile').set(user.auth)).body).toEqual({ email: user.email, ...full });
  });

  it('accepts a partly filled profile and clears fields that are left out or sent as null', async () => {
    const user = await signUp(app);
    await http().put('/me/profile').set(user.auth).send(full).expect(200);
    const res = await http().put('/me/profile').set(user.auth).send({ bloodGroup: 'AB-', weightKg: null }).expect(200);
    expect(res.body).toMatchObject({ bloodGroup: 'AB-', weightKg: null, name: null, heightCm: null, conditions: null });
  });

  it('does not let the profile change the email or password', async () => {
    const user = await signUp(app);
    await http().put('/me/profile').set(user.auth).send({ email: 'other@example.com' }).expect(400);
    await http().put('/me/profile').set(user.auth).send({ passwordHash: 'x' }).expect(400);
  });

  it.each([
    ['height below range', { heightCm: 10 }],
    ['height above range', { heightCm: 400 }],
    ['height as text', { heightCm: 'tall' }],
    ['weight of zero', { weightKg: 0 }],
    ['weight above range', { weightKg: 900 }],
    ['unknown blood group', { bloodGroup: 'C+' }],
    ['unknown sex', { sex: 'YES' }],
    ['malformed date of birth', { dateOfBirth: '17/05/1990' }],
    ['impossible date of birth', { dateOfBirth: '1990-02-30' }],
    ['date of birth in the future', { dateOfBirth: '2999-01-01' }],
    ['date of birth before 1900', { dateOfBirth: '1850-01-01' }],
    ['invalid emergency phone', { emergencyPhone: 'call mum' }],
    ['over-long name', { name: 'x'.repeat(121) }],
    ['over-long conditions', { conditions: 'x'.repeat(501) }],
  ])('rejects %s with 400 and changes nothing', async (_label, body) => {
    const user = await signUp(app);
    await http().put('/me/profile').set(user.auth).send(full).expect(200);
    await http().put('/me/profile').set(user.auth).send({ ...full, ...body }).expect(400);
    expect((await http().get('/me/profile').set(user.auth)).body).toEqual({ email: user.email, ...full });
  });

  it("keeps each user's profile separate", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    await http().put('/me/profile').set(alice.auth).send(full).expect(200);
    expect((await http().get('/me/profile').set(bob.auth)).body.name).toBeNull();
  });

  it('requires a token', async () => {
    await http().get('/me/profile').expect(401);
    await http().put('/me/profile').send(full).expect(401);
  });

  it('is not used by chat: long-term conditions never produce a medicine', async () => {
    const user = await signUp(app);
    await http().put('/me/profile').set(user.auth).send({ conditions: 'sore throat' }).expect(200);
    const chat = await http().post('/chat').set(user.auth).send({ message: 'I have a sore throat' }).expect(200);
    expect(chat.body).toMatchObject({ kind: 'NO_HISTORY', medicines: [] });
  });
});
