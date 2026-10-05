import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { confirmBody, confirmed, createApp, schedule, signUp, type TestUser, upload } from './support/app.js';

describe('S2 confirm and S3 timeline (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());
  const confirm = (user: TestUser, documentId: string, body: unknown) =>
    http().post(`/documents/${documentId}/confirm`).set(user.auth).send(body as object);

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('saves only the values the user confirmed, not what was extracted', async () => {
    const user = await signUp(app);
    const doc = await upload(app, user);
    expect(doc.body.extraction.condition).toBe('Sore throat');

    const edited = confirmBody({ condition: 'Throat infection' });
    edited.medicines[0].dose = '650 mg, 1 tablet';
    const res = await confirm(user, doc.body.id, edited).expect(201);

    expect(res.body.condition).toBe('Throat infection');
    expect(res.body.medicines[0]).toMatchObject({ name: 'Paracetamol', dose: '650 mg, 1 tablet', source: 'PRESCRIPTION' });
    expect(res.body.medicines[0].schedule).toMatchObject({
      slots: ['MORNING', 'NOON', 'NIGHT'],
      food: 'AFTER_FOOD',
      dosesPerDay: 3,
      courseDays: 5,
      startDate: '2026-10-01',
      endDate: '2026-10-06',
    });
    expect(res.body.doctor).toMatchObject({ name: 'Dr. A. Mehra', registrationNo: 'MH-00000-DEMO' });
    const stored = await http().get(`/documents/${doc.body.id}`).set(user.auth).expect(200);
    expect(stored.body.status).toBe('CONFIRMED');
  });

  it('adds nothing to the timeline when the user leaves without confirming', async () => {
    const user = await signUp(app);
    await upload(app, user);
    const timeline = await http().get('/prescriptions').set(user.auth).expect(200);
    expect(timeline.body).toEqual([]);
    const prisma = app.get(PrismaService);
    expect(await prisma.medicine.count({ where: { user: { email: user.email } } })).toBe(0);
    expect(await prisma.schedule.count({ where: { user: { email: user.email } } })).toBe(0);
    expect(await prisma.doctor.count({ where: { user: { email: user.email } } })).toBe(0);
  });

  it('accepts manual entry after a failed extraction', async () => {
    const user = await signUp(app);
    const doc = await upload(app, user, 'unreadable.png');
    expect(doc.body.status).toBe('EXTRACTION_FAILED');
    await confirm(user, doc.body.id, confirmBody()).expect(201);
  });

  it('lists the timeline newest first with condition, medicines and prescriber', async () => {
    const user = await signUp(app);
    await confirmed(app, user, { condition: 'Headache', date: '2025-08-18' });
    await confirmed(app, user, { condition: 'Sore throat', date: '2026-03-12' });
    await confirmed(app, user, { condition: 'Seasonal allergy', date: '2025-12-02' });

    const timeline = await http().get('/prescriptions').set(user.auth).expect(200);
    expect(timeline.body.map((p: { date: string }) => p.date)).toEqual(['2026-03-12', '2025-12-02', '2025-08-18']);
    expect(timeline.body[0]).toMatchObject({ condition: 'Sore throat', doctor: { name: 'Dr. A. Mehra' } });
    expect(timeline.body[0].medicines.map((m: { name: string }) => m.name)).toEqual(['Paracetamol', 'Cetirizine']);
    expect(timeline.body[0].adherence).toEqual({ taken: 0, total: 20 });
  });

  it('returns one prescription by id', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    const res = await http().get(`/prescriptions/${p.id}`).set(user.auth).expect(200);
    expect(res.body.id).toBe(p.id);
  });

  it("never shows another user's entries", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const p = await confirmed(app, alice);
    const timeline = await http().get('/prescriptions').set(bob.auth).expect(200);
    expect(timeline.body).toEqual([]);
    await http().get(`/prescriptions/${p.id}`).set(bob.auth).expect(404);
  });

  it("refuses to confirm another user's document", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const doc = await upload(app, alice);
    await confirm(bob, doc.body.id, confirmBody()).expect(404);
  });

  it('refuses to confirm the same document twice', async () => {
    const user = await signUp(app);
    const doc = await upload(app, user);
    await confirm(user, doc.body.id, confirmBody()).expect(201);
    await confirm(user, doc.body.id, confirmBody()).expect(409);
    const timeline = await http().get('/prescriptions').set(user.auth).expect(200);
    expect(timeline.body).toHaveLength(1);
  });

  describe('schedule must be complete and valid before confirm', () => {
    const medicine = (s: unknown) => [{ name: 'Paracetamol', dose: '500 mg', schedule: s }];
    const { food: _food, ...noFood } = schedule();
    const { courseDays: _course, ...noCourse } = schedule();

    it.each([
      ['missing schedule', [{ name: 'Paracetamol', dose: '500 mg' }]],
      ['missing food timing', medicine(noFood)],
      ['missing course length', medicine(noCourse)],
      ['no slots', medicine(schedule({ slots: [], dosesPerDay: 1 }))],
      ['invalid slot', medicine(schedule({ slots: ['MIDNIGHT'], dosesPerDay: 1 }))],
      ['duplicate slot', medicine(schedule({ slots: ['NIGHT', 'NIGHT'], dosesPerDay: 2 }))],
      ['zero doses per day', medicine(schedule({ dosesPerDay: 0 }))],
      ['negative doses per day', medicine(schedule({ dosesPerDay: -1 }))],
      ['doses per day not matching slots', medicine(schedule({ dosesPerDay: 2 }))],
      ['course length over the limit', medicine(schedule({ courseDays: 366 }))],
      ['zero course length', medicine(schedule({ courseDays: 0 }))],
      ['invalid start date', medicine(schedule({ startDate: '2026-02-30' }))],
      ['no medicines', []],
      ['empty medicine name', [{ name: ' ', dose: '500 mg', schedule: schedule() }].map((m) => ({ ...m, name: '' }))],
    ])('rejects %s with 400 and saves nothing', async (_label, medicines) => {
      const user = await signUp(app);
      const doc = await upload(app, user);
      await confirm(user, doc.body.id, confirmBody({ medicines })).expect(400);
      const timeline = await http().get('/prescriptions').set(user.auth).expect(200);
      expect(timeline.body).toEqual([]);
    });

    it.each([
      ['empty condition', { condition: '' }],
      ['over-long condition', { condition: 'x'.repeat(121) }],
      ['invalid date', { date: '12-03-2026' }],
      ['missing doctor', { doctor: undefined }],
      ['empty doctor name', { doctor: { name: '' } }],
      ['invalid doctor phone', { doctor: { name: 'Dr. A. Mehra', phone: 'call me' } }],
      ['unknown field', { severity: 'high' }],
    ])('rejects %s with 400', async (_label, overrides) => {
      const user = await signUp(app);
      const doc = await upload(app, user);
      await confirm(user, doc.body.id, confirmBody(overrides)).expect(400);
    });
  });
});
