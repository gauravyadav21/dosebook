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
      reminder: null,
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

  describe('reminders on a note (S15)', () => {
    const weekly = { frequency: 'WEEKLY', time: '07:30', weekday: 1 };

    it('creates a note with a daily, weekly or monthly reminder and returns it', async () => {
      const user = await signUp(app);
      const daily = await http().post('/notes').set(user.auth).send({ text: 'Drink water', reminder: { frequency: 'DAILY', time: '09:00' } }).expect(201);
      expect(daily.body.reminder).toEqual({ frequency: 'DAILY', time: '09:00' });
      const week = await http().post('/notes').set(user.auth).send({ text: 'Weigh myself', reminder: weekly }).expect(201);
      expect(week.body.reminder).toEqual(weekly);
      const month = await http()
        .post('/notes')
        .set(user.auth)
        .send({ text: 'Refill', reminder: { frequency: 'MONTHLY', time: '18:00', dayOfMonth: 28 } })
        .expect(201);
      expect(month.body.reminder).toEqual({ frequency: 'MONTHLY', time: '18:00', dayOfMonth: 28 });
      const list = await http().get('/notes').set(user.auth).expect(200);
      expect(list.body.map((n: { reminder: unknown }) => n.reminder)).toEqual([month.body.reminder, week.body.reminder, daily.body.reminder]);
    });

    it('creates a one-time reminder with a date, and changes it to a repeating one and back (S15)', async () => {
      const user = await signUp(app);
      const once = { frequency: 'ONCE', time: '14:30', date: '2026-10-12' };
      const note = await http().post('/notes').set(user.auth).send({ text: 'Call the lab', reminder: once }).expect(201);
      expect(note.body.reminder).toEqual(once);
      const id = note.body.id;

      const daily = await http()
        .patch(`/notes/${id}`)
        .set(user.auth)
        .send({ text: 'Call the lab', reminder: { frequency: 'DAILY', time: '09:00' } })
        .expect(200);
      expect(daily.body.reminder).toEqual({ frequency: 'DAILY', time: '09:00' });

      const again = await http().patch(`/notes/${id}`).set(user.auth).send({ text: 'Call the lab', reminder: once }).expect(200);
      expect(again.body.reminder).toEqual(once);
      expect((await http().get('/notes').set(user.auth)).body[0].reminder).toEqual(once);
    });

    it('keeps the reminder when only the text changes, changes it, and removes it with null', async () => {
      const user = await signUp(app);
      const note = await http().post('/notes').set(user.auth).send({ text: 'Weigh myself', reminder: weekly }).expect(201);
      const id = note.body.id;

      const edited = await http().patch(`/notes/${id}`).set(user.auth).send({ text: 'Weigh myself after waking' }).expect(200);
      expect(edited.body.reminder).toEqual(weekly);

      const changed = await http()
        .patch(`/notes/${id}`)
        .set(user.auth)
        .send({ text: 'Weigh myself after waking', reminder: { frequency: 'MONTHLY', time: '08:00', dayOfMonth: 5 } })
        .expect(200);
      expect(changed.body.reminder).toEqual({ frequency: 'MONTHLY', time: '08:00', dayOfMonth: 5 });

      const cleared = await http().patch(`/notes/${id}`).set(user.auth).send({ text: 'Weigh myself after waking', reminder: null }).expect(200);
      expect(cleared.body.reminder).toBeNull();
      expect((await http().get('/notes').set(user.auth)).body[0].reminder).toBeNull();
    });

    it.each([
      ['weekly without a weekday', { frequency: 'WEEKLY', time: '09:00' }],
      ['a weekday above 7', { frequency: 'WEEKLY', time: '09:00', weekday: 8 }],
      ['monthly without a day', { frequency: 'MONTHLY', time: '09:00' }],
      ['a day of the month above 28', { frequency: 'MONTHLY', time: '09:00', dayOfMonth: 29 }],
      ['a weekday on a daily reminder', { frequency: 'DAILY', time: '09:00', weekday: 1 }],
      ['a time that is not HH:mm', { frequency: 'DAILY', time: '9am' }],
      ['an hour past 23', { frequency: 'DAILY', time: '24:00' }],
      ['a missing time', { frequency: 'DAILY' }],
      ['one time without a date', { frequency: 'ONCE', time: '09:00' }],
      ['one time with a date that is not a day', { frequency: 'ONCE', time: '09:00', date: '2026-02-30' }],
      ['one time with a badly written date', { frequency: 'ONCE', time: '09:00', date: '12 Oct 2026' }],
      ['a date on a daily reminder', { frequency: 'DAILY', time: '09:00', date: '2026-10-12' }],
      ['an unknown frequency', { frequency: 'HOURLY', time: '09:00' }],
      ['another field', { frequency: 'DAILY', time: '09:00', sound: 'bell' }],
      ['a non-integer weekday', { frequency: 'WEEKLY', time: '09:00', weekday: 1.5 }],
      ['a reminder that is not an object', 'daily'],
    ])('rejects %s with 400', async (_label, reminder) => {
      const user = await signUp(app);
      await http().post('/notes').set(user.auth).send({ text: 'x', reminder }).expect(400);
      const note = await http().post('/notes').set(user.auth).send({ text: 'x' }).expect(201);
      await http().patch(`/notes/${note.body.id}`).set(user.auth).send({ text: 'x', reminder }).expect(400);
      expect((await http().get('/notes').set(user.auth)).body[0].reminder).toBeNull();
    });

    it("cannot set or clear a reminder on another user's note", async () => {
      const alice = await signUp(app);
      const bob = await signUp(app);
      const note = await http().post('/notes').set(alice.auth).send({ text: 'private', reminder: weekly }).expect(201);
      await http().patch(`/notes/${note.body.id}`).set(bob.auth).send({ text: 'private', reminder: null }).expect(404);
      await http().patch(`/notes/${note.body.id}`).set(bob.auth).send({ text: 'private', reminder: { frequency: 'DAILY', time: '09:00' } }).expect(404);
      expect((await http().get('/notes').set(alice.auth)).body[0].reminder).toEqual(weekly);
    });

    it('does not turn a note into a dose or a Today item', async () => {
      const user = await signUp(app);
      await http().post('/notes').set(user.auth).send({ text: 'Drink water', reminder: { frequency: 'DAILY', time: '09:00' } }).expect(201);
      expect((await http().get('/doses/today').query({ date: '2026-10-04' }).set(user.auth)).body.doses).toEqual([]);
      expect((await http().get('/doses/schedules').query({ date: '2026-10-04' }).set(user.auth)).body).toEqual([]);
      expect((await http().get('/own-reminders').set(user.auth)).body).toEqual([]);
    });
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
      expect.objectContaining({ name: 'Vitamin D3', slot: '21:30', group: 'DINNER', origin: 'YOUR_REMINDER', status: 'DUE' }),
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
    const created = await http().post('/own-reminders').set(user.auth).send({ name: 'Cough syrup', dose: odd, slots: ['DINNER'] }).expect(201);
    expect(created.body.dose).toBe(odd);
    const noDose = await http().post('/own-reminders').set(user.auth).send({ name: 'Paracetamol', slots: ['DINNER'] }).expect(201);
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
    await http().post('/own-reminders').set(user.auth).send({ name: 'Honey lozenge', slots: ['DINNER'] }).expect(201);
    expect((await http().get('/prescriptions').set(user.auth)).body).toEqual([]);
    expect((await http().get('/medicines').set(user.auth)).body).toEqual([]);
    const chat = await http().post('/chat').set(user.auth).send({ message: 'honey lozenge' }).expect(200);
    expect(chat.body.medicines).toEqual([]);
  });

  it.each([
    ['empty name', { name: '', slots: ['DINNER'] }],
    ['missing name', { slots: ['DINNER'] }],
    ['over-long name', { name: 'x'.repeat(121), slots: ['DINNER'] }],
    ['no time at all', { name: 'Vitamin D3' }],
    ['empty slots and times', { name: 'Vitamin D3', slots: [], times: [] }],
    ['invalid time', { name: 'Vitamin D3', times: ['25:00'] }],
    ['malformed time', { name: 'Vitamin D3', times: ['8am'] }],
    ['invalid slot', { name: 'Vitamin D3', slots: ['BRUNCH'] }],
    ['unknown field', { name: 'Vitamin D3', slots: ['DINNER'], prescribedBy: 'Dr. X' }],
  ])('rejects %s with 400', async (_label, body) => {
    const user = await signUp(app);
    await http().post('/own-reminders').set(user.auth).send(body).expect(400);
  });

  it('rejects an edit that would leave no time', async () => {
    const user = await signUp(app);
    const reminder = await http().post('/own-reminders').set(user.auth).send({ name: 'Vitamin D3', slots: ['DINNER'] }).expect(201);
    await http().patch(`/own-reminders/${reminder.body.id}`).set(user.auth).send({ slots: [] }).expect(400);
  });

  it("cannot read or change another user's reminders", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const reminder = await http().post('/own-reminders').set(alice.auth).send({ name: 'Vitamin D3', slots: ['DINNER'] }).expect(201);
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
