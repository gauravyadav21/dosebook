import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { EXTRACTOR } from '../src/extraction/extraction.types.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createApp, JPEG, PDF, PNG, signUp, upload } from './support/app.js';

describe('S1 upload and S2 extraction (e2e)', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());
  const documentCount = async (email: string) =>
    app.get(PrismaService).document.count({ where: { user: { email } } });

  beforeAll(async () => {
    app = await createApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it.each([
    ['sore-throat.png', PNG, 'image/png'],
    ['sore-throat.jpg', JPEG, 'image/jpeg'],
    ['sore-throat.pdf', PDF, 'application/pdf'],
  ])('stores %s and returns editable extracted fields', async (name, data, mime) => {
    const user = await signUp(app);
    const res = await upload(app, user, name, data);
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ fileName: name, mimeType: mime, status: 'EXTRACTED' });
    expect(res.body.extraction).toMatchObject({
      condition: 'Sore throat',
      date: '2026-03-12',
      doctor: { name: 'Dr. A. Mehra', phone: '+91 00000 00101', registrationNo: 'MH-00000-DEMO' },
    });
    expect(res.body.extraction.medicines.map((m: { name: string }) => m.name)).toEqual(['Paracetamol', 'Cetirizine']);
    expect(await documentCount(user.email)).toBe(1);
  });

  it('marks extraction as failed when nothing could be read, so the user can enter details by hand', async () => {
    const user = await signUp(app);
    const res = await upload(app, user, 'holiday-photo.png');
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ status: 'EXTRACTION_FAILED', extraction: null });
  });

  it('rejects an unsupported file type by content, whatever the name says, and stores nothing', async () => {
    const user = await signUp(app);
    const res = await upload(app, user, 'notes.png', Buffer.from('this is plain text, not an image'));
    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/JPEG, PNG or PDF/);
    expect(await documentCount(user.email)).toBe(0);
  });

  it('rejects a file over 10 MB with 400 and stores nothing', async () => {
    const user = await signUp(app);
    const big = Buffer.concat([PNG, Buffer.alloc(10 * 1024 * 1024)]);
    const res = await upload(app, user, 'sore-throat.png', big);
    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/10 MB/);
    expect(await documentCount(user.email)).toBe(0);
  });

  it('rejects a request with no file', async () => {
    const user = await signUp(app);
    await http().post('/documents').set(user.auth).expect(400);
  });

  it('requires a token', async () => {
    await http().post('/documents').attach('file', PNG, 'sore-throat.png').expect(401);
  });

  it("hides another user's document and file", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const doc = await upload(app, alice);
    await http().get(`/documents/${doc.body.id}`).set(alice.auth).expect(200);
    await http().get(`/documents/${doc.body.id}`).set(bob.auth).expect(404);
    await http().get(`/documents/${doc.body.id}/file`).set(bob.auth).expect(404);
  });

  it('returns the stored original file to its owner', async () => {
    const user = await signUp(app);
    const doc = await upload(app, user, 'sore-throat.pdf', PDF);
    const res = await http().get(`/documents/${doc.body.id}/file`).set(user.auth).buffer(true).parse((r, cb) => {
      const chunks: Buffer[] = [];
      r.on('data', (c: Buffer) => chunks.push(c));
      r.on('end', () => cb(null, Buffer.concat(chunks)));
    });
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(Buffer.compare(res.body, PDF)).toBe(0);
  });

  it('does not use the original file name in the storage path', async () => {
    const user = await signUp(app);
    const doc = await upload(app, user, '../../sore-throat.png');
    const row = await app.get(PrismaService).document.findUniqueOrThrow({ where: { id: doc.body.id } });
    expect(row.storagePath).not.toContain('sore-throat');
    expect(row.storagePath).not.toContain('..');
  });

  it('rejects an id that is not a UUID', async () => {
    const user = await signUp(app);
    await http().get('/documents/not-a-uuid').set(user.auth).expect(400);
  });
});

describe('S2 extraction failure (e2e)', () => {
  it('keeps the upload and reports failure when the extractor throws', async () => {
    const app = await createApp((b) =>
      b.overrideProvider(EXTRACTOR).useValue({
        extract: async () => {
          throw new Error('service unavailable');
        },
      }),
    );
    const user = await signUp(app);
    const res = await upload(app, user);
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ status: 'EXTRACTION_FAILED', extraction: null });
    await app.close();
  });
});
