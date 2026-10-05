import { Body, Controller, Delete, Get, HttpCode, NotFoundException, Param, ParseUUIDPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';
import { UserId } from '../auth/auth.decorators.js';
import type { Note } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

export const MAX_NOTE_LENGTH = 5000;

/** An open note: free text only. The app stores it and does nothing else with it (S7). */
export class NoteDto {
  @ApiProperty({ example: 'Ask Dr. Mehra about the cough at the next visit.' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @IsNotEmpty()
  @MaxLength(MAX_NOTE_LENGTH)
  text: string;
}

const view = (n: Note) => ({ id: n.id, text: n.text, createdAt: n.createdAt, updatedAt: n.updatedAt });

@ApiTags('notes')
@ApiBearerAuth()
@Controller('notes')
export class NotesController {
  constructor(private readonly prisma: PrismaService) {}

  /** Most recently changed first. */
  @Get()
  async list(@UserId() userId: string) {
    const rows = await this.prisma.note.findMany({ where: { userId }, orderBy: { updatedAt: 'desc' } });
    return rows.map(view);
  }

  @Post()
  async create(@UserId() userId: string, @Body() dto: NoteDto) {
    return view(await this.prisma.note.create({ data: { userId, text: dto.text } }));
  }

  @Patch(':id')
  async update(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string, @Body() dto: NoteDto) {
    await this.find(userId, id);
    return view(await this.prisma.note.update({ where: { id }, data: { text: dto.text } }));
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.find(userId, id);
    await this.prisma.note.delete({ where: { id } });
  }

  private async find(userId: string, id: string) {
    const row = await this.prisma.note.findFirst({ where: { id, userId } });
    if (!row) throw new NotFoundException('Note not found');
    return row;
  }
}
