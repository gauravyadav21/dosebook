import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { APP_CONFIG, loadConfig } from '../src/common/config.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createApp, PDF, signUp, upload } from './support/app.js';

/** Collects a binary response body. */
const bytes = (r: NodeJS.ReadableStream, cb: (err: Error | null, body: Buffer) => void) => {
  const chunks: Buffer[] = [];
  r.on('data', (c: Buffer) => chunks.push(c));
  r.on('end', () => cb(null, Buffer.concat(chunks)));
};

describe.each(['disk', 'database'] as const)('S13 uploaded files kept in/on %s (e2e)', (fileStorage) => {
  let app: INestApplication;
  let prisma: PrismaService;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createApp((b) => b.overrideProvider(APP_CONFIG).useValue({ ...loadConfig(), fileStorage }));
    prisma = app.get(PrismaService);
  });
  afterAll(async () => {
    await app.close();
  });

  it('gives back exactly the bytes that were uploaded', async () => {
    const user = await signUp(app);
    const doc = await upload(app, user, 'sore-throat.pdf', PDF);
    expect(doc.status).toBe(201);
    const res = await http().get(`/documents/${doc.body.id}/file`).set(user.auth).buffer(true).parse(bytes);
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(Buffer.compare(res.body, PDF)).toBe(0);
  });

  it('keeps the file in the chosen place only', async () => {
    const user = await signUp(app);
    const doc = await upload(app, user);
    const row = await prisma.document.findUniqueOrThrow({ where: { id: doc.body.id }, include: { blob: true } });
    if (fileStorage === 'database') {
      expect(row.storagePath).toBeNull();
      expect(row.blob?.data.length).toBe(row.size);
    } else {
      expect(row.storagePath).toEqual(expect.any(String));
      expect(row.blob).toBeNull();
    }
  });

  it("never serves one user's file to another", async () => {
    const alice = await signUp(app);
    const bob = await signUp(app);
    const doc = await upload(app, alice);
    await http().get(`/documents/${doc.body.id}/file`).set(bob.auth).expect(404);
    await http().get(`/documents/${doc.body.id}/file`).expect(401);
  });

  it('does not return file bytes with the document details', async () => {
    const user = await signUp(app);
    const doc = await upload(app, user);
    const res = await http().get(`/documents/${doc.body.id}`).set(user.auth).expect(200);
    expect(Object.keys(res.body)).not.toContain('blob');
    expect(Object.keys(res.body)).not.toContain('storagePath');
  });

  it('removes the stored bytes when the account is removed', async () => {
    const user = await signUp(app);
    const doc = await upload(app, user);
    await prisma.user.delete({ where: { email: user.email } });
    expect(await prisma.documentBlob.count({ where: { documentId: doc.body.id } })).toBe(0);
    expect(await prisma.document.count({ where: { id: doc.body.id } })).toBe(0);
  });
});
