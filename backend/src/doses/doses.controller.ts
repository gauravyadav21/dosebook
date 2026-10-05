import { BadRequestException, Body, Controller, Get, HttpCode, NotFoundException, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { UserId } from '../auth/auth.decorators.js';
import { IsCalendarDate, todayUtc } from '../common/dates.js';
import { slotGroupOf } from '../common/slots.js';
import { DoseStatus } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { dailySlots, endDateExclusive, isDueOn } from './doses.logic.js';

export class DateQuery {
  @ApiPropertyOptional({ example: '2026-10-04', description: "The user's local date. Defaults to today (UTC)." })
  @IsOptional()
  @IsCalendarDate()
  date?: string;
}

export class MarkDoseDto {
  @ApiProperty()
  @IsUUID()
  medicineId: string;

  @ApiProperty({ example: '2026-10-04' })
  @IsCalendarDate()
  date: string;

  @ApiProperty({ example: 'MORNING', description: 'Slot name, or HH:mm for an own reminder' })
  @IsString()
  @MaxLength(10)
  slot: string;

  @ApiProperty({ enum: DoseStatus })
  @IsEnum(DoseStatus)
  status: DoseStatus;
}

@ApiTags('doses')
@ApiBearerAuth()
@Controller('doses')
export class DosesController {
  constructor(private readonly prisma: PrismaService) {}

  /** Doses due on a date, grouped by part of day, with taken/skipped marks (S6). Built only from confirmed schedules. */
  @Get('today')
  async today(@UserId() userId: string, @Query() query: DateQuery) {
    const date = query.date ?? todayUtc();
    const schedules = await this.prisma.schedule.findMany({
      where: { userId },
      include: { medicine: true },
      orderBy: { createdAt: 'asc' },
    });
    const logs = await this.prisma.doseLog.findMany({ where: { userId, date } });
    const marked = new Map(logs.map((l) => [`${l.medicineId}|${l.slot}`, l]));

    const doses = schedules
      .filter((s) => isDueOn(s, date))
      .flatMap((s) =>
        dailySlots(s).map((slot) => {
          const log = marked.get(`${s.medicineId}|${slot}`);
          return {
            medicineId: s.medicineId,
            name: s.medicine.name,
            dose: s.medicine.dose,
            food: s.food,
            slot,
            group: slotGroupOf(slot),
            // Own reminders are never presented as prescribed (S7).
            origin: s.medicine.source === 'PRESCRIPTION' ? 'AS_PRESCRIBED' : 'YOUR_REMINDER',
            status: log?.status ?? 'DUE',
            markedAt: log?.markedAt ?? null,
          };
        }),
      );
    return { date, doses };
  }

  @Post('mark')
  @HttpCode(200)
  async mark(@UserId() userId: string, @Body() dto: MarkDoseDto) {
    const schedule = await this.prisma.schedule.findFirst({ where: { medicineId: dto.medicineId, userId } });
    if (!schedule) throw new NotFoundException('Medicine not found');
    if (!isDueOn(schedule, dto.date) || !dailySlots(schedule).includes(dto.slot)) {
      throw new BadRequestException('No dose is scheduled for this medicine at that date and time');
    }
    const log = await this.prisma.doseLog.upsert({
      where: { medicineId_date_slot: { medicineId: dto.medicineId, date: dto.date, slot: dto.slot } },
      create: { userId, medicineId: dto.medicineId, date: dto.date, slot: dto.slot, status: dto.status },
      update: { status: dto.status, markedAt: new Date() },
    });
    return { medicineId: log.medicineId, date: log.date, slot: log.slot, status: log.status, markedAt: log.markedAt };
  }

  /** Active schedules, so the phone can set local notifications. Ended and stopped courses are left out. */
  @Get('schedules')
  async schedules(@UserId() userId: string, @Query() query: DateQuery) {
    const date = query.date ?? todayUtc();
    const schedules = await this.prisma.schedule.findMany({ where: { userId }, include: { medicine: true } });
    return schedules
      .filter((s) => {
        const end = endDateExclusive(s);
        return end === null || date < end;
      })
      .map((s) => ({
        medicineId: s.medicineId,
        name: s.medicine.name,
        dose: s.medicine.dose,
        food: s.food,
        slots: dailySlots(s),
        startDate: s.startDate,
        endDate: endDateExclusive(s),
        origin: s.medicine.source === 'PRESCRIPTION' ? 'AS_PRESCRIBED' : 'YOUR_REMINDER',
      }));
  }
}
