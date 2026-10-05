import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags, PartialType } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { UserId } from '../auth/auth.decorators.js';
import { IsCalendarDate, todayUtc } from '../common/dates.js';
import { SLOTS, type Slot, TIME_RE } from '../common/slots.js';
import { medicineInclude, toMedicineView } from '../prescriptions/prescriptions.views.js';
import { PrismaService } from '../prisma/prisma.service.js';

/** A medicine the user takes on their own, with their own reminder times (S7). Never shown as prescribed. */
export class CreateOwnReminderDto {
  @ApiProperty({ example: 'Vitamin D3' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name: string;

  // The user's own words. Stored as typed; the app never checks or corrects it.
  @ApiPropertyOptional({ example: '1 capsule' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  dose?: string;

  @ApiPropertyOptional({ enum: SLOTS, isArray: true })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(4)
  @ArrayUnique()
  @IsIn(SLOTS, { each: true })
  slots?: Slot[];

  @ApiPropertyOptional({ example: ['08:00'], description: 'Clock times as HH:mm' })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @ArrayUnique()
  @Matches(TIME_RE, { each: true, message: 'each time must be HH:mm' })
  times?: string[];

  @ApiPropertyOptional({ description: "The user's local date. Defaults to today (UTC)." })
  @IsOptional()
  @IsCalendarDate()
  startDate?: string;
}

export class UpdateOwnReminderDto extends PartialType(CreateOwnReminderDto) {}

function requireTimes(slots: string[], times: string[]) {
  if (slots.length + times.length === 0) {
    throw new BadRequestException('Choose at least one time for the reminder');
  }
}

@ApiTags('own-reminders')
@ApiBearerAuth()
@Controller('own-reminders')
export class OwnRemindersController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async list(@UserId() userId: string) {
    const rows = await this.prisma.medicine.findMany({
      where: { userId, source: 'SELF' },
      include: medicineInclude,
      orderBy: { createdAt: 'asc' },
    });
    return rows.map(toMedicineView);
  }

  @Post()
  async create(@UserId() userId: string, @Body() dto: CreateOwnReminderDto) {
    const slots = dto.slots ?? [];
    const times = dto.times ?? [];
    requireTimes(slots, times);
    const row = await this.prisma.medicine.create({
      data: {
        userId,
        source: 'SELF',
        name: dto.name.trim(),
        dose: dto.dose?.trim() || null,
        schedule: {
          create: {
            userId,
            slots,
            times,
            food: null,
            dosesPerDay: slots.length + times.length,
            courseDays: null,
            startDate: dto.startDate ?? todayUtc(),
          },
        },
      },
      include: medicineInclude,
    });
    return toMedicineView(row);
  }

  @Patch(':id')
  async update(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateOwnReminderDto) {
    const current = await this.find(userId, id);
    const slots = dto.slots ?? current.schedule?.slots ?? [];
    const times = dto.times ?? current.schedule?.times ?? [];
    requireTimes(slots, times);
    await this.prisma.medicine.update({
      where: { id },
      data: {
        name: dto.name?.trim(),
        dose: dto.dose === undefined ? undefined : dto.dose.trim() || null,
        schedule: {
          upsert: {
            create: {
              userId,
              slots,
              times,
              food: null,
              dosesPerDay: slots.length + times.length,
              courseDays: null,
              startDate: dto.startDate ?? todayUtc(),
            },
            // A changed reminder keeps its start date.
            update: { slots, times, dosesPerDay: slots.length + times.length },
          },
        },
      },
    });
    return toMedicineView(await this.prisma.medicine.findUniqueOrThrow({ where: { id }, include: medicineInclude }));
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.find(userId, id);
    await this.prisma.medicine.delete({ where: { id } });
  }

  /** Only the user's own reminders live here; a prescription medicine cannot be edited through this route. */
  private async find(userId: string, id: string) {
    const row = await this.prisma.medicine.findFirst({ where: { id, userId, source: 'SELF' }, include: { schedule: true } });
    if (!row) throw new NotFoundException('Reminder not found');
    return row;
  }
}
