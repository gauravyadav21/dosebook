import { randomUUID } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { NotFoundException } from '@nestjs/common';
import type { AppConfig } from '../common/config.js';
import type { Document } from '../generated/prisma/client.js';
import type { PrismaService } from '../prisma/prisma.service.js';
import { type AllowedMime, extensionFor } from './file-type.js';

/** The part of a new Document row that says where its file is kept. */
type Placement = { storagePath: string } | { blob: { create: { data: Uint8Array<ArrayBuffer> } } };

/**
 * Where uploaded files are kept. Chosen by FILE_STORAGE: `disk` for development,
 * `database` for hosts whose disk does not last (ADR 0005).
 */
export interface FileStore {
  /** Stores the bytes and returns what to write on the Document row. */
  put(userId: string, mimeType: AllowedMime, data: Buffer): Promise<Placement>;
  read(document: Document): Promise<Buffer>;
}

export const FILE_STORE = Symbol('FILE_STORE');

const GONE = 'The original file is no longer stored';

export class DiskFileStore implements FileStore {
  constructor(private readonly uploadDir: string) {}

  async put(userId: string, mimeType: AllowedMime, data: Buffer): Promise<Placement> {
    // Stored under a generated name: the original name never becomes part of a path.
    const dir = resolve(this.uploadDir, userId);
    await mkdir(dir, { recursive: true });
    const storagePath = join(dir, `${randomUUID()}.${extensionFor(mimeType)}`);
    await writeFile(storagePath, data);
    return { storagePath };
  }

  async read(document: Document): Promise<Buffer> {
    if (!document.storagePath) throw new NotFoundException(GONE);
    try {
      return await readFile(document.storagePath);
    } catch {
      throw new NotFoundException(GONE);
    }
  }
}

export class DatabaseFileStore implements FileStore {
  constructor(private readonly prisma: PrismaService) {}

  /** Nothing is written here: the bytes go in with the Document row, in one statement. */
  async put(_userId: string, _mimeType: AllowedMime, data: Buffer): Promise<Placement> {
    return { blob: { create: { data: new Uint8Array(data) } } };
  }

  async read(document: Document): Promise<Buffer> {
    const blob = await this.prisma.documentBlob.findUnique({ where: { documentId: document.id } });
    if (!blob) throw new NotFoundException(GONE);
    return Buffer.from(blob.data);
  }
}

export function createFileStore(config: AppConfig, prisma: PrismaService): FileStore {
  return config.fileStorage === 'database' ? new DatabaseFileStore(prisma) : new DiskFileStore(config.uploadDir);
}
