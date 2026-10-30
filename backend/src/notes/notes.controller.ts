import { BadRequestException, Body, Controller, Delete, Get, HttpCode, NotFoundException, Param, ParseUUIDPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsIn, IsInt, IsNotEmpty, IsOptional, IsString, Matches, MaxLength, ValidateNested } from 'class-validator';
import { UserId } from '../auth/auth.decorators.js';
import { TIME_RE } from '../common/slots.js';
import type { Note } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { type NoteReminder, reminderProblem, toReminderColumns, toReminderView } from './note-reminder.rules.js';

export const MAX_NOTE_LENGTH = 5000;

export class NoteReminderDto implements NoteReminder {
  @ApiProperty({ enum: ['ONCE', 'DAILY', 'WEEKLY', 'MONTHLY'] })
  @IsIn(['ONCE', 'DAILY', 'WEEKLY', 'MONTHLY'])
  frequency: NoteReminder['frequency'];

  @ApiProperty({ example: '09:00', description: 'Clock time HH:mm' })
  @Matches(TIME_RE, { message: 'time must be HH:mm' })
  time: string;

  @ApiPropertyOptional({ minimum: 1, maximum: 7, description: 'Weekly only. 1 is Monday.' })
  @IsOptional()
  @IsInt()
  weekday?: number;

  @ApiPropertyOptional({ minimum: 1, maximum: 28, description: 'Monthly only.' })
  @IsOptional()
  @IsInt()
  dayOfMonth?: number;

  @ApiPropertyOptional({ example: '2026-10-12', description: 'One-time only. YYYY-MM-DD.' })
  @IsOptional()
  @IsString()
  date?: string;
}

/** An open note: free text, and optionally a reminder the user asked for. The app stores both and reads neither (S7, S15). */
export class NoteDto {
  @ApiProperty({ example: 'Ask Dr. Mehra about the cough at the next visit.' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @IsNotEmpty()
  @MaxLength(MAX_NOTE_LENGTH)
  text: string;

  @ApiPropertyOptional({
    type: NoteReminderDto,
    nullable: true,
    description: 'Leave out to keep the reminder as it is (on a change), send null to remove it.',
  })
  @IsOptional()
  @ValidateNested()
  @Type(() => NoteReminderDto)
  reminder?: NoteReminderDto | null;
}

const view = (n: Note) => ({
  id: n.id,
  text: n.text,
  reminder: toReminderView(n),
  createdAt: n.createdAt,
  updatedAt: n.updatedAt,
});

function checkedReminder(reminder: NoteReminderDto | null | undefined) {
  if (reminder) {
    const problem = reminderProblem(reminder);
    if (problem) throw new BadRequestException(problem);
  }
  return reminder === undefined ? {} : toReminderColumns(reminder ?? null);
}

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
    return view(await this.prisma.note.create({ data: { userId, text: dto.text, ...checkedReminder(dto.reminder) } }));
  }

  @Patch(':id')
  async update(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string, @Body() dto: NoteDto) {
    await this.find(userId, id);
    return view(await this.prisma.note.update({ where: { id }, data: { text: dto.text, ...checkedReminder(dto.reminder) } }));
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
