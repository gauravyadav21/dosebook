import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { confirmed, createApp, signUp } from './support/app.js';

describe('S4 feedback and allergies (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  describe('feedback', () => {
    it('records feedback on a past medicine and lets the user change or clear it', async () => {
      const user = await signUp(app);
      const p = await confirmed(app, user);
      const id = p.medicines[0].id;

      const worked = await http().put(`/medicines/${id}/feedback`).set(user.auth).send({ value: 'WORKED' }).expect(200);
      expect(worked.body.feedback).toBe('WORKED');
      const changed = await http().put(`/medicines/${id}/feedback`).set(user.auth).send({ value: 'SIDE_EFFECT' }).expect(200);
      expect(changed.body.feedback).toBe('SIDE_EFFECT');
      const cleared = await http().put(`/medicines/${id}/feedback`).set(user.auth).send({ value: null }).expect(200);
      expect(cleared.body.feedback).toBeNull();
    });

    it('lists past prescription medicines with their feedback, condition and prescriber', async () => {
      const user = await signUp(app);
      const p = await confirmed(app, user);
      await http().put(`/medicines/${p.medicines[1].id}/feedback`).set(user.auth).send({ value: 'DID_NOT_WORK' }).expect(200);
      const list = await http().get('/medicines').set(user.auth).expect(200);
      expect(list.body).toHaveLength(2);
      expect(list.body[1]).toMatchObject({
        name: 'Cetirizine',
        feedback: 'DID_NOT_WORK',
        condition: 'Sore throat',
        prescriber: 'Dr. A. Mehra',
        date: '2026-03-12',
      });
    });

    it.each([[{ value: 'GREAT' }], [{}], [{ value: 'WORKED', note: 'x' }]])('rejects invalid feedback %j', async (body) => {
      const user = await signUp(app);
      const p = await confirmed(app, user);
      await http().put(`/medicines/${p.medicines[0].id}/feedback`).set(user.auth).send(body).expect(400);
    });

    it("refuses feedback on another user's medicine", async () => {
      const alice = await signUp(app);
      const bob = await signUp(app);
      const p = await confirmed(app, alice);
      await http().put(`/medicines/${p.medicines[0].id}/feedback`).set(bob.auth).send({ value: 'WORKED' }).expect(404);
      const list = await http().get('/medicines').set(bob.auth).expect(200);
      expect(list.body).toEqual([]);
    });
  });

  describe('allergies', () => {
    it('adds, lists and removes an allergy', async () => {
      const user = await signUp(app);
      const added = await http().post('/allergies').set(user.auth).send({ name: '  Penicillin ' }).expect(201);
      expect(added.body.name).toBe('Penicillin');
      const list = await http().get('/allergies').set(user.auth).expect(200);
      expect(list.body).toEqual([{ id: added.body.id, name: 'Penicillin' }]);
      await http().delete(`/allergies/${added.body.id}`).set(user.auth).expect(204);
      expect((await http().get('/allergies').set(user.auth)).body).toEqual([]);
    });

    it('does not duplicate an allergy added twice in different letter case', async () => {
      const user = await signUp(app);
      const first = await http().post('/allergies').set(user.auth).send({ name: 'Penicillin' }).expect(201);
      const second = await http().post('/allergies').set(user.auth).send({ name: 'penicillin' }).expect(201);
      expect(second.body.id).toBe(first.body.id);
      expect((await http().get('/allergies').set(user.auth)).body).toHaveLength(1);
    });

    it.each([[{ name: '' }], [{ name: '   ' }], [{ name: 'x'.repeat(81) }], [{}], [{ name: 42 }]])(
      'rejects invalid input %j',
      async (body) => {
        const user = await signUp(app);
        await http().post('/allergies').set(user.auth).send(body).expect(400);
      },
    );

    it("cannot see or delete another user's allergy", async () => {
      const alice = await signUp(app);
      const bob = await signUp(app);
      const added = await http().post('/allergies').set(alice.auth).send({ name: 'Penicillin' }).expect(201);
      expect((await http().get('/allergies').set(bob.auth)).body).toEqual([]);
      await http().delete(`/allergies/${added.body.id}`).set(bob.auth).expect(404);
      expect((await http().get('/allergies').set(alice.auth)).body).toHaveLength(1);
    });
  });
});
