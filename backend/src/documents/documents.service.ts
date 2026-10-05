import { randomUUID } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { BadRequestException, Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../common/config.js';
import { EXTRACTOR, type ExtractionResult, type Extractor } from '../extraction/extraction.types.js';
import type { Document } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { extensionFor, MAX_FILE_BYTES, sniffMime } from './file-type.js';

export interface UploadedFile {
  originalname: string;
  buffer: Buffer;
  size: number;
}

export function toDocumentView(doc: Document) {
  return {
    id: doc.id,
    fileName: doc.fileName,
    mimeType: doc.mimeType,
    size: doc.size,
    status: doc.status,
    extraction: (doc.extraction as ExtractionResult | null) ?? null,
    createdAt: doc.createdAt,
  };
}

@Injectable()
export class DocumentsService {
  private readonly logger = new Logger(DocumentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
    @Inject(EXTRACTOR) private readonly extractor: Extractor,
  ) {}

  async upload(userId: string, file: UploadedFile | undefined) {
    if (!file || !file.buffer?.length) throw new BadRequestException('Choose a photo or PDF to upload');
    if (file.size > MAX_FILE_BYTES) throw new BadRequestException('File is larger than 10 MB');
    const mimeType = sniffMime(file.buffer);
    if (!mimeType) throw new BadRequestException('File type is not supported. Use a JPEG, PNG or PDF.');

    // Stored under a generated name: the original name never becomes part of a path.
    const dir = resolve(this.config.uploadDir, userId);
    await mkdir(dir, { recursive: true });
    const storagePath = join(dir, `${randomUUID()}.${extensionFor(mimeType)}`);
    await writeFile(storagePath, file.buffer);

    const fileName = file.originalname.slice(0, 200);
    let doc = await this.prisma.document.create({
      data: { userId, fileName, mimeType, size: file.size, storagePath },
    });

    let extraction: ExtractionResult | null = null;
    try {
      extraction = await this.extractor.extract({ fileName, mimeType, data: file.buffer });
    } catch (error) {
      // Extraction is best effort; the user can always enter the details by hand.
      this.logger.warn(`Extraction failed for document ${doc.id}: ${(error as Error).message}`);
    }
    doc = await this.prisma.document.update({
      where: { id: doc.id },
      data: extraction
        ? { status: 'EXTRACTED', extraction: extraction as object }
        : { status: 'EXTRACTION_FAILED' },
    });
    return toDocumentView(doc);
  }

  async get(userId: string, id: string): Promise<Document> {
    const doc = await this.prisma.document.findFirst({ where: { id, userId } });
    if (!doc) throw new NotFoundException('Document not found');
    return doc;
  }
}
