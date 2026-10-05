import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { confirmed, createApp, signUp } from './support/app.js';

describe('S7 open notes (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('creates, edits and deletes a free-text note', async () => {
    const user = await signUp(app);
    const created = await http().post('/notes').set(user.auth).send({ text: '  Ask about the cough next visit.  ' }).expect(201);
    expect(created.body).toEqual({
      id: expect.any(String),
      text: 'Ask about the cough next visit.',
      createdAt: expect.any(String),
      updatedAt: expect.any(String),
    });

    const edited = await http().patch(`/notes/${created.body.id}`).set(user.auth).send({ text: 'Cough is better.' }).expect(200);
    expect(edited.body.text).toBe('Cough is better.');

    await http().delete(`/notes/${created.body.id}`).set(user.auth).expect(204);
    expect((await http().get('/notes').set(user.auth)).body).toEqual([]);
  });

  it('keeps the text exactly as written, including line breaks', async () => {
    const user = await signUp(app);
    const text = 'Line one\n\n- took 2?? not sure\n- 500mg';
    const created = await http().post('/notes').set(user.auth).send({ text }).expect(201);
    expect(created.body.text).toBe(text);
  });

  it('lists the most recently changed note first', async () => {
    const user = await signUp(app);
    const first = await http().post('/notes').set(user.auth).send({ text: 'first' }).expect(201);
    await http().post('/notes').set(user.auth).send({ text: 'second' }).expect(201);
    await http().patch(`/notes/${first.body.id}`).set(user.auth).send({ text: 'first, edited' }).expect(200);
    const list = await http().get('/notes').set(user.auth).expect(200);
    expect(list.body.map((n: { text: string }) => n.text)).toEqual(['first, edited', 'second']);
  });

  it('has no effect on medicines, Today or chat', async () => {
    const user = await signUp(app);
    await http().post('/notes').set(user.auth).send({ text: 'Paracetamol helps my sore throat' }).expect(201);
    expect((await http().get('/medicines').set(user.auth)).body).toEqual([]);
    expect((await http().get('/own-reminders').set(user.auth)).body).toEqual([]);
    expect((await http().get('/doses/today').query({ date: '2026-10-04' }).set(user.auth)).body.doses).toEqual([]);
    const chat = await http().post('/chat').set(user.auth).send({ message: 'I have a sore throat' }).expect(200);
    expect(chat.body).toMatchObject({ kind: 'NO_HISTORY', medicines: [] });
  });

  it.each([
    ['empty text', { text: '' }],
    ['only spaces', { text: '   ' }],
    ['missing text', {}],
    ['over-long text', { text: 'x'.repeat(5001) }],
    ['a non-string', { text: 42 }],
    ['any other field', { text: 'ok', name: 'Vitamin D3' }],
  ])('rejects %s with 400', async (_label, body) => {
    const user = await signUp(app);
    await http().post('/notes').set(user.auth).send(body).expect(400);
  });

  it("cannot read or change another user's notes", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const note = await http().post('/notes').set(alice.auth).send({ text: 'private' }).expect(201);
    expect((await http().get('/notes').set(bob.auth)).body).toEqual([]);
    await http().patch(`/notes/${note.body.id}`).set(bob.auth).send({ text: 'changed' }).expect(404);
    await http().delete(`/notes/${note.body.id}`).set(bob.auth).expect(404);
    expect((await http().get('/notes').set(alice.auth)).body[0].text).toBe('private');
  });

  it('requires a token', async () => {
    await http().get('/notes').expect(401);
  });
});

describe('S7 own reminders (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('creates an own reminder that shows in Today as "your reminder", with taken/skipped like a prescribed dose', async () => {
    const user = await signUp(app);
    const reminder = await http()
      .post('/own-reminders')
      .set(user.auth)
      .send({ name: 'Vitamin D3', dose: '1 capsule', slots: ['MORNING'], times: ['21:30'], startDate: '2026-10-01' })
      .expect(201);
    expect(reminder.body).toMatchObject({ source: 'SELF', name: 'Vitamin D3', dose: '1 capsule' });
    expect(reminder.body.schedule).toMatchObject({ slots: ['MORNING'], times: ['21:30'], courseDays: null, endDate: null });

    const day = await http().get('/doses/today').query({ date: '2027-01-15' }).set(user.auth).expect(200);
    expect(day.body.doses).toEqual([
      expect.objectContaining({ name: 'Vitamin D3', slot: 'MORNING', group: 'MORNING', origin: 'YOUR_REMINDER', food: null, status: 'DUE' }),
      expect.objectContaining({ name: 'Vitamin D3', slot: '21:30', group: 'NIGHT', origin: 'YOUR_REMINDER', status: 'DUE' }),
    ]);

    await http()
      .post('/doses/mark')
      .set(user.auth)
      .send({ medicineId: reminder.body.id, date: '2027-01-15', slot: '21:30', status: 'SKIPPED' })
      .expect(200);
    const after = await http().get('/doses/today').query({ date: '2027-01-15' }).set(user.auth).expect(200);
    expect(after.body.doses[1].status).toBe('SKIPPED');
  });

  it('stores the dose exactly as typed: no autofill, validation or correction', async () => {
    const user = await signUp(app);
    const odd = 'approx 2-3 spoons?? whenever';
    const created = await http().post('/own-reminders').set(user.auth).send({ name: 'Cough syrup', dose: odd, slots: ['NIGHT'] }).expect(201);
    expect(created.body.dose).toBe(odd);
    const noDose = await http().post('/own-reminders').set(user.auth).send({ name: 'Paracetamol', slots: ['NIGHT'] }).expect(201);
    expect(noDose.body.dose).toBeNull();
  });

  it('changes the times and keeps the start date; deleting removes it from Today', async () => {
    const user = await signUp(app);
    const reminder = await http()
      .post('/own-reminders')
      .set(user.auth)
      .send({ name: 'Vitamin D3', slots: ['MORNING'], startDate: '2026-10-01' })
      .expect(201);

    const changed = await http()
      .patch(`/own-reminders/${reminder.body.id}`)
      .set(user.auth)
      .send({ slots: [], times: ['08:00', '20:00'] })
      .expect(200);
    expect(changed.body.schedule).toMatchObject({ slots: [], times: ['08:00', '20:00'], startDate: '2026-10-01' });

    const renamed = await http().patch(`/own-reminders/${reminder.body.id}`).set(user.auth).send({ name: 'Vitamin D' }).expect(200);
    expect(renamed.body).toMatchObject({ name: 'Vitamin D' });
    expect(renamed.body.schedule.times).toEqual(['08:00', '20:00']);

    await http().delete(`/own-reminders/${reminder.body.id}`).set(user.auth).expect(204);
    expect((await http().get('/doses/today').query({ date: '2026-10-02' }).set(user.auth)).body.doses).toEqual([]);
  });

  it('stays out of the prescription timeline, the prescription medicine list and chat', async () => {
    const user = await signUp(app);
    await http().post('/own-reminders').set(user.auth).send({ name: 'Honey lozenge', slots: ['NIGHT'] }).expect(201);
    expect((await http().get('/prescriptions').set(user.auth)).body).toEqual([]);
    expect((await http().get('/medicines').set(user.auth)).body).toEqual([]);
    const chat = await http().post('/chat').set(user.auth).send({ message: 'honey lozenge' }).expect(200);
    expect(chat.body.medicines).toEqual([]);
  });

  it.each([
    ['empty name', { name: '', slots: ['NIGHT'] }],
    ['missing name', { slots: ['NIGHT'] }],
    ['over-long name', { name: 'x'.repeat(121), slots: ['NIGHT'] }],
    ['no time at all', { name: 'Vitamin D3' }],
    ['empty slots and times', { name: 'Vitamin D3', slots: [], times: [] }],
    ['invalid time', { name: 'Vitamin D3', times: ['25:00'] }],
    ['malformed time', { name: 'Vitamin D3', times: ['8am'] }],
    ['invalid slot', { name: 'Vitamin D3', slots: ['BRUNCH'] }],
    ['unknown field', { name: 'Vitamin D3', slots: ['NIGHT'], prescribedBy: 'Dr. X' }],
  ])('rejects %s with 400', async (_label, body) => {
    const user = await signUp(app);
    await http().post('/own-reminders').set(user.auth).send(body).expect(400);
  });

  it('rejects an edit that would leave no time', async () => {
    const user = await signUp(app);
    const reminder = await http().post('/own-reminders').set(user.auth).send({ name: 'Vitamin D3', slots: ['NIGHT'] }).expect(201);
    await http().patch(`/own-reminders/${reminder.body.id}`).set(user.auth).send({ slots: [] }).expect(400);
  });

  it("cannot read or change another user's reminders", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const reminder = await http().post('/own-reminders').set(alice.auth).send({ name: 'Vitamin D3', slots: ['NIGHT'] }).expect(201);
    expect((await http().get('/own-reminders').set(bob.auth)).body).toEqual([]);
    await http().patch(`/own-reminders/${reminder.body.id}`).set(bob.auth).send({ name: 'Changed' }).expect(404);
    await http().delete(`/own-reminders/${reminder.body.id}`).set(bob.auth).expect(404);
    expect((await http().get('/own-reminders').set(alice.auth)).body[0].name).toBe('Vitamin D3');
  });

  it('does not let a prescription medicine be edited or deleted as an own reminder', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    await http().patch(`/own-reminders/${p.medicines[0].id}`).set(user.auth).send({ dose: '1000 mg' }).expect(404);
    await http().delete(`/own-reminders/${p.medicines[0].id}`).set(user.auth).expect(404);
  });
});
