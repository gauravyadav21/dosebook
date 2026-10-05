import { BadRequestException, Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { EXTRACTOR, type ExtractionResult, type Extractor } from '../extraction/extraction.types.js';
import type { Document } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { FILE_STORE, type FileStore } from './file-store.js';
import { MAX_FILE_BYTES, sniffMime } from './file-type.js';

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
    @Inject(FILE_STORE) private readonly files: FileStore,
    @Inject(EXTRACTOR) private readonly extractor: Extractor,
  ) {}

  async upload(userId: string, file: UploadedFile | undefined) {
    if (!file || !file.buffer?.length) throw new BadRequestException('Choose a photo or PDF to upload');
    if (file.size > MAX_FILE_BYTES) throw new BadRequestException('File is larger than 10 MB');
    const mimeType = sniffMime(file.buffer);
    if (!mimeType) throw new BadRequestException('File type is not supported. Use a JPEG, PNG or PDF.');

    const placement = await this.files.put(userId, mimeType, file.buffer);
    const fileName = file.originalname.slice(0, 200);
    let doc = await this.prisma.document.create({
      data: { userId, fileName, mimeType, size: file.size, ...placement },
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

  /** The stored original, for its owner only. */
  async file(userId: string, id: string): Promise<{ data: Buffer; mimeType: string }> {
    const doc = await this.get(userId, id);
    return { data: await this.files.read(doc), mimeType: doc.mimeType };
  }
}
