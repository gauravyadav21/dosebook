import { randomUUID } from 'node:crypto';
import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { DECLINED_TEXT, DOSAGE_TEXT, ESCALATION_TEXT, FOOTER_TEXT, LOOKUP_UNAVAILABLE_TEXT } from '../src/chat/chat.rules.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { GENERAL_INFO_DISCLAIMER, MEDICINE_INFO_PROVIDER, type LookupResult } from '../src/medicine-info/medicine-info.js';
import { confirmed, createApp, signUp, type TestUser } from './support/app.js';

const names = (body: { medicines: { name: string }[] }) => body.medicines.map((m) => m.name);

describe('S5 chat: symptom recall, and S8 messaging (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());
  const ask = async (user: TestUser, message: string) =>
    (await http().post('/chat').set(user.auth).send({ message }).expect(200)).body;

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('recalls medicines taken for the same condition, with dose, prescriber, date, recorded feedback and the doctor-vs-app line', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    await http().put(`/medicines/${p.medicines[0].id}/feedback`).set(user.auth).send({ value: 'WORKED' }).expect(200);

    const body = await ask(user, 'I have a sore throat');
    expect(body.kind).toBe('RECALL');
    expect(body.footer).toBe(FOOTER_TEXT);
    expect(body.medicines[0]).toMatchObject({
      name: 'Paracetamol',
      dose: '500 mg, 1 tablet',
      prescriber: 'Dr. A. Mehra',
      date: '2026-03-12',
      feedback: 'WORKED',
      sourceLabel: 'From prescription',
    });
    // No feedback recorded is reported as such; chat does not ask for it.
    expect(body.medicines[1]).toMatchObject({ name: 'Cetirizine', feedback: null });
    expect(names(body)).toEqual(['Paracetamol', 'Cetirizine']);
  });

  it('says so and suggests a doctor when there is no matching history; no medicine is invented', async () => {
    const user = await signUp(app);
    await confirmed(app, user);
    const body = await ask(user, 'I have a stomach upset');
    expect(body.kind).toBe('NO_HISTORY');
    expect(body.medicines).toEqual([]);
    expect(body.text).toMatch(/see a doctor/i);
    expect(body.footer).toBe(FOOTER_TEXT);
  });

  it.each(['DID_NOT_WORK', 'SIDE_EFFECT'])('does not recall a medicine marked %s', async (value) => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    await http().put(`/medicines/${p.medicines[1].id}/feedback`).set(user.auth).send({ value }).expect(200);
    const body = await ask(user, 'sore throat again');
    expect(names(body)).toEqual(['Paracetamol']);
    expect(body.excludedCount).toBe(1);
  });

  it('stops recalling a medicine as soon as a matching allergy is added', async () => {
    const user = await signUp(app);
    await confirmed(app, user);
    expect(names(await ask(user, 'sore throat'))).toContain('Paracetamol');
    await http().post('/allergies').set(user.auth).send({ name: 'paracetamol' }).expect(201);
    expect(names(await ask(user, 'sore throat'))).toEqual(['Cetirizine']);
  });

  it('escalates with no medicine list when every matching medicine is blocked', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    for (const m of p.medicines) {
      await http().put(`/medicines/${m.id}/feedback`).set(user.auth).send({ value: 'DID_NOT_WORK' }).expect(200);
    }
    const body = await ask(user, 'sore throat');
    expect(body).toMatchObject({ kind: 'ESCALATION', text: ESCALATION_TEXT, medicines: [] });
  });

  it.each([
    'I have chest pain and trouble breathing',
    'sore throat and a very high fever',
    'sore throat and I fainted this morning',
  ])('redirects red-flag symptoms to a doctor and lists no medicines: %s', async (message) => {
    const user = await signUp(app);
    await confirmed(app, user);
    const body = await ask(user, message);
    expect(body).toMatchObject({ kind: 'ESCALATION', reason: 'RED_FLAG', text: ESCALATION_TEXT, medicines: [] });
    expect(body.emergency).toMatch(/emergency number/);
    expect(body.footer).toBe(FOOTER_TEXT);
  });

  it.each([
    ['a new medicine', 'give me a new medicine for my sore throat'],
    ['stopping a course', 'should I stop taking the tablets for my sore throat'],
    ['pregnancy', 'I am pregnant and have a sore throat'],
    ['a child', 'my child has a sore throat'],
    ['an interaction', 'can I mix paracetamol with alcohol for my sore throat'],
    ['a diagnosis', 'what do I have, is it serious, sore throat'],
    ['a long-lasting symptom', 'sore throat for 3 weeks'],
    ['a worsening symptom', 'my sore throat is getting worse'],
  ])('escalates a request involving %s and lists no medicines', async (_label, message) => {
    const user = await signUp(app);
    await confirmed(app, user);
    const body = await ask(user, message);
    expect(body).toMatchObject({ kind: 'ESCALATION', text: ESCALATION_TEXT, medicines: [] });
  });

  it.each([
    'how much paracetamol can I take',
    'what is the dose of paracetamol',
    'can I take a double dose of paracetamol for my sore throat',
    'paracetamol 500 mg how many times a day',
    'how often should I have cetirizine',
  ])('refuses a dosage question and tells the user to visit a doctor: %s', async (message) => {
    const user = await signUp(app);
    await confirmed(app, user);
    const body = await ask(user, message);
    expect(body).toMatchObject({ kind: 'DECLINED', reason: 'DOSAGE', text: DOSAGE_TEXT, medicines: [] });
    expect(body.generalInfo).toBeUndefined();
    expect(body.footer).toBe(FOOTER_TEXT);
  });

  it("never answers from another user's history", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    await confirmed(app, alice);
    expect(await ask(bob, 'I have a sore throat')).toMatchObject({ kind: 'NO_HISTORY', medicines: [] });
    expect((await ask(bob, 'paracetamol')).medicines).toEqual([]);
  });

  it.each([
    'hello',
    'tell me a joke please, a long one',
    'what is the weather like today in the city',
    'write an email to my manager for me',
    'who won the match yesterday evening',
  ])('declines anything that is neither a symptom nor a medicine lookup: %s', async (message) => {
    const user = await signUp(app);
    await confirmed(app, user);
    const body = await ask(user, message);
    expect(body).toMatchObject({ kind: 'DECLINED', text: DECLINED_TEXT, medicines: [] });
    expect(body.footer).toBe(FOOTER_TEXT);
  });

  it.each([[{ message: '' }], [{}], [{ message: 'x'.repeat(501) }], [{ message: 'sore throat', history: [] }]])(
    'rejects invalid input %j',
    async (body) => {
      const user = await signUp(app);
      await http().post('/chat').set(user.auth).send(body).expect(400);
    },
  );
});

describe('S5 chat: medicine lookup without a model (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());
  const ask = async (user: TestUser, message: string) =>
    (await http().post('/chat').set(user.auth).send({ message }).expect(200)).body;

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it.each(['paracetamol', 'what is Paracetamol?', 'tell me about paracetamol', 'when did I take paracetamol'])(
    'shows the user\'s own record of a medicine: "%s"',
    async (message) => {
      const user = await signUp(app);
      const p = await confirmed(app, user);
      await http().put(`/medicines/${p.medicines[0].id}/feedback`).set(user.auth).send({ value: 'WORKED' }).expect(200);
      const body = await ask(user, message);
      expect(body).toMatchObject({ kind: 'MEDICINE_INFO', medicineName: 'Paracetamol', allergyMatch: false, footer: FOOTER_TEXT });
      expect(body.medicines).toEqual([
        expect.objectContaining({
          name: 'Paracetamol',
          dose: '500 mg, 1 tablet',
          condition: 'Sore throat',
          prescriber: 'Dr. A. Mehra',
          date: '2026-03-12',
          feedback: 'WORKED',
        }),
      ]);
    },
  );

  it('lists every time the medicine was prescribed, newest first', async () => {
    const user = await signUp(app);
    await confirmed(app, user, { condition: 'Fever', date: '2025-01-10' });
    await confirmed(app, user, { condition: 'Sore throat', date: '2026-03-12' });
    const body = await ask(user, 'paracetamol');
    expect(body.medicines.map((m: { condition: string }) => m.condition)).toEqual(['Sore throat', 'Fever']);
  });

  it('still shows the record of a medicine the user marked or is allergic to, and flags the allergy', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    await http().put(`/medicines/${p.medicines[0].id}/feedback`).set(user.auth).send({ value: 'SIDE_EFFECT' }).expect(200);
    await http().post('/allergies').set(user.auth).send({ name: 'Paracetamol' }).expect(201);
    const body = await ask(user, 'paracetamol');
    expect(body).toMatchObject({ kind: 'MEDICINE_INFO', allergyMatch: true });
    expect(body.medicines[0]).toMatchObject({ name: 'Paracetamol', feedback: 'SIDE_EFFECT' });
  });

  it('says a medicine is not in the records and that no general information is saved', async () => {
    const user = await signUp(app);
    await confirmed(app, user);
    const body = await ask(user, `what is Zelnorvex${randomUUID().slice(0, 6)}`);
    expect(body.kind).toBe('MEDICINE_INFO');
    expect(body.medicines).toEqual([]);
    expect(body.generalInfo).toBeNull();
    expect(body.text).toMatch(/not in your own records/);
    expect(body.text).toMatch(/No general information is saved/);
  });

  it('gives no dose advice even when asked through a lookup', async () => {
    const user = await signUp(app);
    await confirmed(app, user);
    expect(await ask(user, 'what is the right dose of paracetamol, should I take more tablets')).toMatchObject({
      kind: 'DECLINED',
      reason: 'DOSAGE',
      text: DOSAGE_TEXT,
      medicines: [],
    });
  });
});

describe('S5 chat: medicine lookup with a model, saved for reuse (e2e)', () => {
  const calls: string[] = [];
  let reply: (name: string) => LookupResult | null = () => null;
  let app: INestApplication;
  const http = () => request(app.getHttpServer());
  const ask = async (user: TestUser, message: string) =>
    (await http().post('/chat').set(user.auth).send({ message }).expect(200)).body;
  const unique = (prefix: string) => `${prefix}${randomUUID().replace(/-/g, '').slice(0, 8)}`;

  beforeAll(async () => {
    app = await createApp((b) =>
      b.overrideProvider(MEDICINE_INFO_PROVIDER).useValue({
        lookup: async (name: string) => {
          calls.push(name);
          return reply(name);
        },
      }),
    );
  });
  beforeEach(() => {
    calls.length = 0;
  });
  afterAll(async () => {
    await app.close();
  });

  it('fetches general information once, saves it, and answers later lookups from the saved copy', async () => {
    const medicine = unique('Fakemed');
    reply = () => ({ isMedicine: true, name: medicine, usedFor: 'Usually prescribed in tests.', storage: 'Keep in a cool, dry place.' });
    const alice = await signUp(app);
    const bob = await signUp(app);

    const first = await ask(alice, `what is ${medicine}`);
    expect(first).toMatchObject({
      kind: 'MEDICINE_INFO',
      medicineName: medicine,
      medicines: [],
      generalInfo: { usedFor: 'Usually prescribed in tests.', storage: 'Keep in a cool, dry place.', disclaimer: GENERAL_INFO_DISCLAIMER },
    });
    // Exactly these three keys: nothing else about the medicine is returned.
    expect(Object.keys(first.generalInfo).sort()).toEqual(['disclaimer', 'storage', 'usedFor']);
    expect(calls).toHaveLength(1);

    // Same medicine again, another user, different letter case: no second call.
    const second = await ask(bob, `tell me about ${medicine.toUpperCase()}`);
    expect(second.generalInfo).toEqual(first.generalInfo);
    expect(calls).toHaveLength(1);
  });

  it('answers from a row saved before storage was recorded, without calling the model', async () => {
    const medicine = unique('Oldrow');
    await app.get(PrismaService).medicineInfo.create({
      data: { nameKey: medicine.toLowerCase(), name: medicine, summary: 'Usually prescribed in old tests.', source: 'GEMINI' },
    });
    const user = await signUp(app);
    const body = await ask(user, `what is ${medicine}`);
    expect(body.generalInfo).toEqual({ usedFor: 'Usually prescribed in old tests.', storage: null, disclaimer: GENERAL_INFO_DISCLAIMER });
    expect(calls).toEqual([]);
  });

  it('sends only the medicine name to the lookup, never the message or user data', async () => {
    const medicine = unique('Onlyname');
    reply = () => ({ isMedicine: true, name: medicine, usedFor: 'Usually prescribed in tests.', storage: null });
    const user = await signUp(app);
    await confirmed(app, user);
    await ask(user, `please tell me about ${medicine} tablets`);
    expect(calls).toEqual([medicine.toLowerCase()]);
  });

  it('adds general information to the user\'s own record of a medicine', async () => {
    reply = (name) => ({ isMedicine: true, name, usedFor: 'A made-up use.', storage: 'Keep dry.' });
    const user = await signUp(app);
    await confirmed(app, user, {
      medicines: [
        {
          name: unique('Ownmed'),
          dose: '1 tablet',
          schedule: { slots: ['DINNER'], food: 'AFTER_FOOD', dosesPerDay: 1, courseDays: 3, startDate: '2026-10-01' },
        },
      ],
    });
    const timeline = await http().get('/prescriptions').set(user.auth).expect(200);
    const name: string = timeline.body[0].medicines[0].name;
    const body = await ask(user, name);
    expect(body).toMatchObject({ kind: 'MEDICINE_INFO', medicineName: name });
    expect(body.medicines).toHaveLength(1);
    expect(body.generalInfo).toEqual({ usedFor: 'A made-up use.', storage: 'Keep dry.', disclaimer: GENERAL_INFO_DISCLAIMER });
  });

  it('declines and saves nothing when the name is not a medicine', async () => {
    const word = unique('notamed');
    reply = () => ({ isMedicine: false });
    const user = await signUp(app);
    expect(await ask(user, `what is ${word}`)).toMatchObject({ kind: 'DECLINED', text: DECLINED_TEXT, medicines: [] });
    expect(calls).toHaveLength(1);
    // Not saved: asked again, the lookup runs again.
    await ask(user, `what is ${word}`);
    expect(calls).toHaveLength(2);
  });

  it('answers without general information when the lookup fails', async () => {
    const medicine = unique('Failmed');
    reply = () => {
      throw new Error('service unavailable');
    };
    const user = await signUp(app);
    const body = await ask(user, `what is ${medicine}`);
    expect(body).toMatchObject({ kind: 'MEDICINE_INFO', generalInfo: null, medicines: [] });
  });

  it('says the lookup is unavailable, not that the request is out of scope, when a bare medicine name cannot be looked up', async () => {
    // Found on the emulator on 5 Oct 2026: the lookup timed out and "cetirizine" got the generic refusal.
    const medicine = unique('Slowmed');
    reply = () => {
      throw new Error('The operation was aborted due to timeout');
    };
    const user = await signUp(app);
    const body = await ask(user, medicine);
    expect(body).toMatchObject({ kind: 'DECLINED', text: LOOKUP_UNAVAILABLE_TEXT, medicines: [] });
    expect(body.text).not.toBe(DECLINED_TEXT);
    expect(body.generalInfo ?? null).toBeNull();
  });

  it('does not call the lookup for symptoms, red flags, dosage questions or long off-topic messages', async () => {
    reply = () => ({ isMedicine: true, name: 'x', usedFor: 'x', storage: null });
    const user = await signUp(app);
    await confirmed(app, user);
    for (const message of [
      'I have a sore throat',
      'I have a stomach upset',
      'chest pain',
      'how much paracetamol can I take',
      'what is the dose of ibuprofen',
      'ibuprofen dosage',
      'write an email to my manager for me',
    ]) {
      await ask(user, message);
    }
    expect(calls).toEqual([]);
  });
});
