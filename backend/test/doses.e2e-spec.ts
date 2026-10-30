import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { confirmed, createApp, schedule, signUp, type TestUser, upload } from './support/app.js';

interface Dose {
  medicineId: string;
  name: string;
  slot: string;
  group: string;
  origin: string;
  status: string;
  food: string | null;
  dose: string | null;
}

describe('S6 dose reminders and Today (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());
  const today = async (user: TestUser, date: string): Promise<Dose[]> =>
    (await http().get('/doses/today').query({ date }).set(user.auth).expect(200)).body.doses;
  const mark = (user: TestUser, body: object) => http().post('/doses/mark').set(user.auth).send(body);

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('lists a dose for each confirmed slot, with medicine, dose and food note from the prescription', async () => {
    const user = await signUp(app);
    await confirmed(app, user);
    const doses = await today(user, '2026-10-01');
    expect(doses.map((d) => `${d.name}:${d.slot}`)).toEqual([
      'Paracetamol:MORNING',
      'Paracetamol:LUNCH',
      'Paracetamol:DINNER',
      'Cetirizine:DINNER',
    ]);
    expect(doses[0]).toMatchObject({
      dose: '500 mg, 1 tablet',
      food: 'AFTER_FOOD',
      group: 'MORNING',
      origin: 'AS_PRESCRIBED',
      status: 'DUE',
    });
  });

  it('has doses on every day of the course and none before or after', async () => {
    const user = await signUp(app);
    await confirmed(app, user);
    expect(await today(user, '2026-09-30')).toEqual([]);
    expect(await today(user, '2026-10-01')).toHaveLength(4);
    expect(await today(user, '2026-10-05')).toHaveLength(4);
    expect(await today(user, '2026-10-06')).toEqual([]);
  });

  it('creates no doses from an unconfirmed upload', async () => {
    const user = await signUp(app);
    await upload(app, user);
    expect(await today(user, '2026-10-01')).toEqual([]);
    expect((await http().get('/doses/schedules').query({ date: '2026-10-01' }).set(user.auth)).body).toEqual([]);
  });

  it('marks a dose taken or skipped, lets the user change it, and counts it in the adherence log', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    const medicineId = p.medicines[0].id;

    const taken = await mark(user, { medicineId, date: '2026-10-01', slot: 'MORNING', status: 'TAKEN' }).expect(200);
    expect(taken.body).toMatchObject({ status: 'TAKEN', slot: 'MORNING' });
    await mark(user, { medicineId, date: '2026-10-01', slot: 'LUNCH', status: 'SKIPPED' }).expect(200);

    let doses = await today(user, '2026-10-01');
    expect(doses.slice(0, 3).map((d) => d.status)).toEqual(['TAKEN', 'SKIPPED', 'DUE']);

    await mark(user, { medicineId, date: '2026-10-01', slot: 'LUNCH', status: 'TAKEN' }).expect(200);
    doses = await today(user, '2026-10-01');
    expect(doses[1].status).toBe('TAKEN');

    const timeline = await http().get('/prescriptions').set(user.auth).expect(200);
    expect(timeline.body[0].medicines[0].adherence).toEqual({ taken: 2, total: 15 });
    expect(timeline.body[0].adherence).toEqual({ taken: 2, total: 20 });
  });

  it.each([
    ['a slot not in the schedule', { date: '2026-10-01', slot: '09:30', status: 'TAKEN' }],
    ['a date after the course', { date: '2026-10-06', slot: 'MORNING', status: 'TAKEN' }],
    ['a date before the course', { date: '2026-09-30', slot: 'MORNING', status: 'TAKEN' }],
    ['an invalid status', { date: '2026-10-01', slot: 'MORNING', status: 'MAYBE' }],
    ['an invalid date', { date: 'yesterday', slot: 'MORNING', status: 'TAKEN' }],
  ])('rejects marking %s with 400', async (_label, body) => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    await mark(user, { medicineId: p.medicines[0].id, ...body }).expect(400);
  });

  it("cannot read or mark another user's doses", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const p = await confirmed(app, alice);
    expect(await today(bob, '2026-10-01')).toEqual([]);
    await mark(bob, { medicineId: p.medicines[0].id, date: '2026-10-01', slot: 'MORNING', status: 'TAKEN' }).expect(404);
    expect((await today(alice, '2026-10-01'))[0].status).toBe('DUE');
  });

  it('stops a course: no dose is due from the stop date on, earlier marks stay', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    const id = p.medicines[0].id;
    await mark(user, { medicineId: id, date: '2026-10-01', slot: 'MORNING', status: 'TAKEN' }).expect(200);

    const stopped = await http().post(`/medicines/${id}/schedule/stop`).set(user.auth).send({ date: '2026-10-03' }).expect(200);
    expect(stopped.body.schedule).toMatchObject({ stopped: true, endDate: '2026-10-03' });
    expect(stopped.body.adherence).toEqual({ taken: 1, total: 6 });

    expect((await today(user, '2026-10-02')).map((d) => d.name)).toContain('Paracetamol');
    expect((await today(user, '2026-10-03')).map((d) => d.name)).toEqual(['Cetirizine']);
  });

  it('edits a course: Today and reminders follow the new schedule', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    const id = p.medicines[0].id;
    const edited = await http()
      .patch(`/medicines/${id}/schedule`)
      .set(user.auth)
      .send(schedule({ slots: ['MORNING', 'DINNER'], dosesPerDay: 2, courseDays: 7 }))
      .expect(200);
    expect(edited.body.schedule).toMatchObject({ slots: ['MORNING', 'DINNER'], courseDays: 7, endDate: '2026-10-08' });
    const doses = await today(user, '2026-10-07');
    expect(doses.map((d) => `${d.name}:${d.slot}`)).toEqual(['Paracetamol:MORNING', 'Paracetamol:DINNER']);
  });

  it('edits a course with a chosen time: Today shows it at that time, grouped by the part of the day (S14)', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    const id = p.medicines[0].id;
    const edited = await http()
      .patch(`/medicines/${id}/schedule`)
      .set(user.auth)
      .send(schedule({ slots: ['LUNCH'], times: ['19:15'], dosesPerDay: 2 }))
      .expect(200);
    expect(edited.body.schedule).toMatchObject({ slots: ['LUNCH'], times: ['19:15'] });
    const doses = (await today(user, '2026-10-02')).filter((d) => d.name === 'Paracetamol');
    expect(doses.map((d) => `${d.slot}:${d.group}`)).toEqual(['LUNCH:LUNCH', '19:15:DINNER']);
    const phone = await http().get('/doses/schedules').query({ date: '2026-10-02' }).set(user.auth).expect(200);
    expect(phone.body[0].slots).toEqual(['LUNCH', '19:15']);
  });

  it('allows five or ten doses a day, several in the same part of the day (S14)', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    const id = p.medicines[0].id;
    const five = ['07:00', '09:00', '11:00', '13:00', '15:00'];
    const edited = await http()
      .patch(`/medicines/${id}/schedule`)
      .set(user.auth)
      .send(schedule({ slots: [], times: five, dosesPerDay: 5 }))
      .expect(200);
    expect(edited.body.schedule).toMatchObject({ times: five, dosesPerDay: 5 });
    const doses = (await today(user, '2026-10-02')).filter((d) => d.name === 'Paracetamol');
    expect(doses.map((d) => d.slot)).toEqual(five);
    expect(doses.map((d) => d.group)).toEqual(['MORNING', 'MORNING', 'LUNCH', 'LUNCH', 'LUNCH']);
  });

  it('confirms a prescription with a chosen time and keeps it (S14)', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user, {
      medicines: [{ name: 'Metformin', dose: '500 mg', schedule: schedule({ slots: ['DINNER'], times: ['07:30'], dosesPerDay: 2 }) }],
    });
    expect(p.medicines[0].schedule).toMatchObject({ slots: ['DINNER'], times: ['07:30'] });
    expect((await today(user, '2026-10-01')).map((d) => `${d.slot}:${d.group}`)).toEqual(['07:30:MORNING', 'DINNER:DINNER']);
  });

  it("keeps a dose marked today when its time is changed (S14)", async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    const id = p.medicines[0].id;
    const day = new Date().toISOString().slice(0, 10);
    await http().patch(`/medicines/${id}/schedule`).set(user.auth).send(schedule({ startDate: day, courseDays: 5 })).expect(200);
    await mark(user, { medicineId: id, date: day, slot: 'MORNING', status: 'TAKEN' }).expect(200);

    await http()
      .patch(`/medicines/${id}/schedule`)
      .set(user.auth)
      .send(schedule({ slots: ['LUNCH', 'DINNER'], times: ['07:30'], dosesPerDay: 3, startDate: day, courseDays: 5 }))
      .expect(200);
    const doses = (await today(user, day)).filter((d) => d.name === 'Paracetamol');
    expect(doses.map((d) => `${d.slot}:${d.status}`)).toEqual(['07:30:TAKEN', 'LUNCH:DUE', 'DINNER:DUE']);
  });

  it.each([
    ['an old slot name', schedule({ slots: ['NOON'], dosesPerDay: 1 })],
    ['a time that is not HH:mm', schedule({ slots: [], times: ['7.30'], dosesPerDay: 1 })],
    ['two doses at the same time', schedule({ slots: ['MORNING'], times: ['08:00'], dosesPerDay: 2 })],
    ['no time of day at all', schedule({ slots: [], dosesPerDay: 1 })],
    ['thirteen doses', schedule({ slots: [], times: Array.from({ length: 13 }, (_, i) => `${String(i + 6).padStart(2, '0')}:00`), dosesPerDay: 13 })],
    ['zero doses', schedule({ dosesPerDay: 0 })],
    ['course too long', schedule({ courseDays: 1000 })],
    ['doses not matching slots', schedule({ dosesPerDay: 1 })],
  ])('rejects a schedule edit with %s', async (_label, body) => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    await http().patch(`/medicines/${p.medicines[0].id}/schedule`).set(user.auth).send(body).expect(400);
  });

  it("cannot edit or stop another user's course", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const p = await confirmed(app, alice);
    const id = p.medicines[0].id;
    await http().patch(`/medicines/${id}/schedule`).set(bob.auth).send(schedule()).expect(404);
    await http().post(`/medicines/${id}/schedule/stop`).set(bob.auth).send({}).expect(404);
  });

  it('lists only active schedules for the phone to set notifications', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    const during = await http().get('/doses/schedules').query({ date: '2026-10-02' }).set(user.auth).expect(200);
    expect(during.body).toHaveLength(2);
    expect(during.body[0]).toMatchObject({
      name: 'Paracetamol',
      slots: ['MORNING', 'LUNCH', 'DINNER'],
      startDate: '2026-10-01',
      endDate: '2026-10-06',
      origin: 'AS_PRESCRIBED',
    });

    await http().post(`/medicines/${p.medicines[0].id}/schedule/stop`).set(user.auth).send({ date: '2026-10-02' }).expect(200);
    const afterStop = await http().get('/doses/schedules').query({ date: '2026-10-02' }).set(user.auth).expect(200);
    expect(afterStop.body.map((s: { name: string }) => s.name)).toEqual(['Cetirizine']);

    const afterCourse = await http().get('/doses/schedules').query({ date: '2026-10-06' }).set(user.auth).expect(200);
    expect(afterCourse.body).toEqual([]);
  });
});
