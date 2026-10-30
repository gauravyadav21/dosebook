import { randomUUID } from 'node:crypto';
import type { INestApplication } from '@nestjs/common';
import { Test, type TestingModuleBuilder } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../../src/app.module.js';
import { configureApp } from '../../src/configure-app.js';

/** Boots the real application pipeline. Tests never share users, so files can run in parallel on one database. */
export async function createApp(
  customize: (builder: TestingModuleBuilder) => TestingModuleBuilder = (b) => b,
): Promise<INestApplication> {
  const moduleRef = await customize(Test.createTestingModule({ imports: [AppModule] })).compile();
  const app = configureApp(moduleRef.createNestApplication());
  await app.init();
  return app;
}

export interface TestUser {
  email: string;
  password: string;
  token: string;
  /** Authorization header for supertest's .set(). */
  auth: { Authorization: string };
}

/** Registers a fresh fake user. */
export async function signUp(app: INestApplication): Promise<TestUser> {
  const email = `user-${randomUUID()}@example.com`;
  const password = 'correct-horse-battery';
  const res = await request(app.getHttpServer()).post('/auth/register').send({ email, password }).expect(201);
  const token: string = res.body.accessToken;
  return { email, password, token, auth: { Authorization: `Bearer ${token}` } };
}

// Smallest byte strings that pass the content check. They are not real images.
export const PNG = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(32)]);
export const JPEG = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(32)]);
export const PDF = Buffer.from('%PDF-1.4\n% fake test file\n');

export async function upload(app: INestApplication, user: TestUser, fileName = 'sore-throat.png', data: Buffer = PNG) {
  return request(app.getHttpServer()).post('/documents').set(user.auth).attach('file', data, fileName);
}

export function schedule(overrides: Record<string, unknown> = {}) {
  return { slots: ['MORNING', 'LUNCH', 'DINNER'], food: 'AFTER_FOOD', dosesPerDay: 3, courseDays: 5, startDate: '2026-10-01', ...overrides };
}

/** Body for POST /documents/:id/confirm, matching the fake "sore throat" sample. */
export function confirmBody(overrides: Record<string, unknown> = {}) {
  return {
    condition: 'Sore throat',
    date: '2026-03-12',
    doctor: {
      name: 'Dr. A. Mehra',
      phone: '+91 00000 00101',
      registrationNo: 'MH-00000-DEMO',
      specialty: 'General physician',
      availability: 'Mon to Sat, 10 am to 1 pm',
    },
    medicines: [
      { name: 'Paracetamol', dose: '500 mg, 1 tablet', frequency: '3 times a day', duration: '5 days', schedule: schedule() },
      {
        name: 'Cetirizine',
        dose: '10 mg, 1 tablet',
        frequency: 'at night',
        duration: '5 days',
        schedule: schedule({ slots: ['DINNER'], dosesPerDay: 1 }),
      },
    ],
    ...overrides,
  };
}

/** Uploads and confirms one prescription; returns the prescription view. */
export async function confirmed(app: INestApplication, user: TestUser, overrides: Record<string, unknown> = {}) {
  const doc = await upload(app, user);
  const res = await request(app.getHttpServer())
    .post(`/documents/${doc.body.id}/confirm`)
    .set(user.auth)
    .send(confirmBody(overrides))
    .expect(201);
  return res.body;
}
