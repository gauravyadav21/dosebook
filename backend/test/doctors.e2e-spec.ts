import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { confirmBody, confirmed, createApp, signUp, type TestUser, upload } from './support/app.js';

describe('S9 doctor contacts (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());
  const doctors = async (user: TestUser) => (await http().get('/doctors').set(user.auth).expect(200)).body;
  const confirm = async (user: TestUser, overrides: Record<string, unknown>) => {
    const doc = await upload(app, user);
    return http().post(`/documents/${doc.body.id}/confirm`).set(user.auth).send(confirmBody(overrides));
  };

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('creates a contact card from a confirmed prescription and shows it on the prescription', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    expect(p.doctor).toEqual({
      id: expect.any(String),
      name: 'Dr. A. Mehra',
      specialty: 'General physician',
      registrationNo: 'MH-00000-DEMO',
      phone: '+91 00000 00101',
      availability: 'Mon to Sat, 10 am to 1 pm',
    });
    expect(await doctors(user)).toEqual([{ ...p.doctor, prescriptionCount: 1 }]);
  });

  it('needs only the doctor name; other details are optional', async () => {
    const user = await signUp(app);
    const res = await confirm(user, { doctor: { name: 'Dr. S. Khan' } });
    expect(res.status).toBe(201);
    expect(res.body.doctor).toMatchObject({ name: 'Dr. S. Khan', phone: null, registrationNo: null, specialty: null });
  });

  it('links a second prescription with the same registration number to the existing card', async () => {
    const user = await signUp(app);
    const first = await confirmed(app, user);
    const second = await confirmed(app, user, {
      condition: 'Headache',
      date: '2025-08-18',
      doctor: { name: 'A. Mehra', registrationNo: 'mh-00000-demo' },
    });
    expect(second.doctor.id).toBe(first.doctor.id);
    expect(await doctors(user)).toEqual([expect.objectContaining({ name: 'Dr. A. Mehra', prescriptionCount: 2 })]);
  });

  it('links on the same name and phone when there is no registration number', async () => {
    const user = await signUp(app);
    const first = await confirmed(app, user, { doctor: { name: 'Dr. R. Iyer', phone: '+91 00000 00102' } });
    const second = await confirmed(app, user, { doctor: { name: 'dr r iyer', phone: '+91-00000-00102' } });
    expect(second.doctor.id).toBe(first.doctor.id);
    expect(await doctors(user)).toHaveLength(1);
  });

  it('asks "Same doctor?" when only the name matches, and never merges silently', async () => {
    const user = await signUp(app);
    const first = await confirmed(app, user);
    const res = await confirm(user, { doctor: { name: 'Dr. A. Mehra' } });
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('DOCTOR_NAME_MATCH');
    expect(res.body.candidates).toEqual([expect.objectContaining({ id: first.doctor.id, name: 'Dr. A. Mehra' })]);
    expect(await doctors(user)).toEqual([expect.objectContaining({ prescriptionCount: 1 })]);
    expect((await http().get('/prescriptions').set(user.auth)).body).toHaveLength(1);
  });

  it('links to the existing card when the user answers "same doctor"', async () => {
    const user = await signUp(app);
    const first = await confirmed(app, user);
    const res = await confirm(user, { doctor: { name: 'Dr. A. Mehra' }, sameDoctorId: first.doctor.id });
    expect(res.status).toBe(201);
    expect(res.body.doctor.id).toBe(first.doctor.id);
    expect(await doctors(user)).toEqual([expect.objectContaining({ prescriptionCount: 2 })]);
  });

  it('creates a second card when the user answers "new doctor"', async () => {
    const user = await signUp(app);
    const first = await confirmed(app, user);
    const res = await confirm(user, { doctor: { name: 'Dr. A. Mehra' }, newDoctor: true });
    expect(res.status).toBe(201);
    expect(res.body.doctor.id).not.toBe(first.doctor.id);
    expect(await doctors(user)).toHaveLength(2);
  });

  it('fills in details a later prescription adds, without overwriting existing ones', async () => {
    const user = await signUp(app);
    const first = await confirmed(app, user, { doctor: { name: 'Dr. R. Iyer', registrationNo: 'KA-00000-DEMO' } });
    const second = await confirmed(app, user, {
      doctor: { name: 'Dr. R. Iyer', registrationNo: 'KA-00000-DEMO', phone: '+91 00000 00102', specialty: 'Allergy specialist' },
    });
    expect(second.doctor).toMatchObject({ id: first.doctor.id, phone: '+91 00000 00102', specialty: 'Allergy specialist' });
    const third = await confirmed(app, user, {
      doctor: { name: 'Dr. R. Iyer', registrationNo: 'KA-00000-DEMO', phone: '+91 00000 00999' },
    });
    expect(third.doctor.phone).toBe('+91 00000 00102');
  });

  it('opens every prescription recorded against a doctor, newest first', async () => {
    const user = await signUp(app);
    const first = await confirmed(app, user, { condition: 'Headache', date: '2025-08-18' });
    await confirmed(app, user, { condition: 'Sore throat', date: '2026-03-12' });
    await confirmed(app, user, { condition: 'Seasonal allergy', date: '2025-12-02', doctor: { name: 'Dr. R. Iyer' } });

    const card = await http().get(`/doctors/${first.doctor.id}`).set(user.auth).expect(200);
    expect(card.body).toMatchObject({ name: 'Dr. A. Mehra', prescriptionCount: 2 });
    expect(card.body.prescriptions.map((p: { condition: string }) => p.condition)).toEqual(['Sore throat', 'Headache']);
  });

  it("shares the doctor's contact only: no condition, medicine or note", async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    const res = await http().get(`/doctors/${p.doctor.id}/share`).set(user.auth).expect(200);
    expect(res.body.text).toBe(
      [
        'Dr. A. Mehra',
        'General physician',
        'Phone: +91 00000 00101',
        'Registration no.: MH-00000-DEMO',
        'Availability: Mon to Sat, 10 am to 1 pm',
        'As printed on a prescription. Not verified.',
      ].join('\n'),
    );
    expect(res.body.text).not.toMatch(/sore throat|paracetamol|cetirizine/i);
  });

  it('edits a card, including adding a missing phone number and clearing a field', async () => {
    const user = await signUp(app);
    const p = (await confirm(user, { doctor: { name: 'Dr. S. Khan', specialty: 'Dentist' } })).body;
    const edited = await http()
      .patch(`/doctors/${p.doctor.id}`)
      .set(user.auth)
      .send({ phone: '+91 00000 00103', specialty: null })
      .expect(200);
    expect(edited.body).toMatchObject({ name: 'Dr. S. Khan', phone: '+91 00000 00103', specialty: null });
  });

  it.each([
    ['invalid phone', { phone: '12' }],
    ['phone with letters', { phone: 'call the clinic' }],
    ['empty name', { name: '' }],
    ['over-long specialty', { specialty: 'x'.repeat(81) }],
    ['over-long availability', { availability: 'x'.repeat(161) }],
    ['unknown field', { verified: true }],
  ])('rejects an edit with %s', async (_label, body) => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    await http().patch(`/doctors/${p.doctor.id}`).set(user.auth).send(body).expect(400);
  });

  it('refuses a registration number that another card already has', async () => {
    const user = await signUp(app);
    await confirmed(app, user);
    const other = (await confirm(user, { doctor: { name: 'Dr. R. Iyer' } })).body;
    await http().patch(`/doctors/${other.doctor.id}`).set(user.auth).send({ registrationNo: 'mh-00000-demo' }).expect(409);
  });

  it('deletes a card and keeps its prescriptions', async () => {
    const user = await signUp(app);
    const p = await confirmed(app, user);
    await http().delete(`/doctors/${p.doctor.id}`).set(user.auth).expect(204);
    expect(await doctors(user)).toEqual([]);
    const kept = await http().get(`/prescriptions/${p.id}`).set(user.auth).expect(200);
    expect(kept.body.doctor).toBeNull();
    expect(kept.body.medicines).toHaveLength(2);
  });

  it("cannot list, read, share, change or delete another user's doctors", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const p = await confirmed(app, alice);
    const id = p.doctor.id;
    expect(await doctors(bob)).toEqual([]);
    await http().get(`/doctors/${id}`).set(bob.auth).expect(404);
    await http().get(`/doctors/${id}/share`).set(bob.auth).expect(404);
    await http().patch(`/doctors/${id}`).set(bob.auth).send({ name: 'Changed' }).expect(404);
    await http().delete(`/doctors/${id}`).set(bob.auth).expect(404);
    const res = await confirm(bob, { doctor: { name: 'Dr. A. Mehra' }, sameDoctorId: id });
    expect(res.status).toBe(404);
    expect((await doctors(alice))[0].name).toBe('Dr. A. Mehra');
  });

  it('keeps two users with the same doctor on separate cards', async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const a = await confirmed(app, alice);
    const b = await confirmed(app, bob);
    expect(b.doctor.id).not.toBe(a.doctor.id);
  });

  it('requires a token', async () => {
    await http().get('/doctors').expect(401);
  });
});
