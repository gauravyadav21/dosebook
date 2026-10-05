import { createReadStream } from 'node:fs';
import {
  type ArgumentsHost,
  BadRequestException,
  Catch,
  Controller,
  type ExceptionFilter,
  Get,
  Param,
  ParseUUIDPipe,
  PayloadTooLargeException,
  Post,
  StreamableFile,
  UploadedFile,
  UseFilters,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { UserId } from '../auth/auth.decorators.js';
import { DocumentsService, toDocumentView, type UploadedFile as Upload } from './documents.service.js';
import { MAX_FILE_BYTES } from './file-type.js';

/** The upload story asks for 400 on an oversize file; the framework's default is 413. */
@Catch(PayloadTooLargeException)
class OversizeFilter implements ExceptionFilter {
  catch(_exception: PayloadTooLargeException, host: ArgumentsHost) {
    const error = new BadRequestException('File is larger than 10 MB');
    host.switchToHttp().getResponse().status(400).json(error.getResponse());
  }
}

@ApiTags('documents')
@ApiBearerAuth()
@Controller('documents')
export class DocumentsController {
  constructor(private readonly documents: DocumentsService) {}

  @Post()
  @UseFilters(OversizeFilter)
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_FILE_BYTES, files: 1 } }))
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } }, required: ['file'] } })
  upload(@UserId() userId: string, @UploadedFile() file: Upload | undefined) {
    return this.documents.upload(userId, file);
  }

  @Get(':id')
  async get(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string) {
    return toDocumentView(await this.documents.get(userId, id));
  }

  @Get(':id/file')
  async file(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string): Promise<StreamableFile> {
    const doc = await this.documents.get(userId, id);
    return new StreamableFile(createReadStream(doc.storagePath), { type: doc.mimeType });
  }
}
