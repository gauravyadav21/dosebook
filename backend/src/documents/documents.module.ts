import { Module } from '@nestjs/common';
import { ExtractionModule } from '../extraction/extraction.module.js';
import { DocumentsController } from './documents.controller.js';
import { APP_CONFIG, type AppConfig } from '../common/config.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { DocumentsService } from './documents.service.js';
import { createFileStore, FILE_STORE } from './file-store.js';

@Module({
  imports: [ExtractionModule],
  controllers: [DocumentsController],
  providers: [
    DocumentsService,
    {
      provide: FILE_STORE,
      useFactory: (config: AppConfig, prisma: PrismaService) => createFileStore(config, prisma),
      inject: [APP_CONFIG, PrismaService],
    },
  ],
  exports: [DocumentsService],
})
export class DocumentsModule {}
