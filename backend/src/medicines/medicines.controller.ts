import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
} from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsEnum, IsOptional, ValidateIf } from 'class-validator';
import { UserId } from '../auth/auth.decorators.js';
import { IsCalendarDate, todayUtc } from '../common/dates.js';
import { slotGroupOf } from '../common/slots.js';
import { FeedbackValue } from '../generated/prisma/enums.js';
import { medicineInclude, toMedicineView } from '../prescriptions/prescriptions.views.js';
import { dailySlots } from '../doses/doses.logic.js';
import { ScheduleDto } from '../prescriptions/schedule.dto.js';
import { scheduleProblem } from '../prescriptions/schedule.rules.js';
import { PrismaService } from '../prisma/prisma.service.js';

export class FeedbackDto {
  @ApiProperty({ enum: FeedbackValue, nullable: true, description: 'null clears the feedback' })
  @ValidateIf((o: FeedbackDto) => o.value !== null)
  @IsEnum(FeedbackValue)
  value: FeedbackValue | null;
}

export class StopDto {
  @ApiPropertyOptional({ description: "The user's local date. Defaults to today (UTC)." })
  @IsOptional()
  @IsCalendarDate()
  date?: string;
}

@ApiTags('medicines')
@ApiBearerAuth()
@Controller('medicines')
export class MedicinesController {
  constructor(private readonly prisma: PrismaService) {}

  /** Past medicines from prescriptions, newest prescription first, for the feedback screen (S4). */
  @Get()
  async list(@UserId() userId: string) {
    const rows = await this.prisma.medicine.findMany({
      where: { userId, source: 'PRESCRIPTION' },
      include: { ...medicineInclude, prescription: { include: { doctor: true } } },
      orderBy: [{ prescription: { date: 'desc' } }, { position: 'asc' }],
    });
    return rows.map((m) => ({
      ...toMedicineView(m),
      prescriptionId: m.prescriptionId,
      condition: m.prescription?.condition ?? null,
      date: m.prescription?.date ?? null,
      prescriber: m.prescription?.doctor?.name ?? null,
    }));
  }

  @Put(':id/feedback')
  async feedback(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string, @Body() dto: FeedbackDto) {
    await this.find(userId, id);
    const row = await this.prisma.medicine.update({
      where: { id },
      data: { feedback: dto.value },
      include: medicineInclude,
    });
    return toMedicineView(row);
  }

  /** Edit a course. Pending reminders follow the new schedule; past dose marks are kept (S6). */
  @Patch(':id/schedule')
  async editSchedule(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string, @Body() dto: ScheduleDto) {
    const medicine = await this.find(userId, id);
    if (medicine.source !== 'PRESCRIPTION' || !medicine.schedule) {
      throw new BadRequestException('This medicine has no prescribed course. Edit your own reminder in Notes.');
    }
    const times = dto.times ?? [];
    const problem = scheduleProblem(dto.slots, times, dto.dosesPerDay);
    if (problem) throw new BadRequestException(problem);
    const before = dailySlots(medicine.schedule);
    const after = dailySlots({ ...medicine.schedule, slots: dto.slots, times });
    const today = todayUtc();
    await this.prisma.$transaction(async (tx) => {
      await tx.schedule.update({
        where: { medicineId: id },
        data: {
          slots: dto.slots,
          times,
          food: dto.food,
          dosesPerDay: dto.dosesPerDay,
          courseDays: dto.courseDays,
          startDate: dto.startDate ?? medicine.schedule!.startDate,
        },
      });
      // A dose already marked today stays marked when its time moves (S14): re-key it to the new time of that part of the day.
      for (const slot of before.filter((b) => !after.includes(b))) {
        const log = await tx.doseLog.findUnique({ where: { medicineId_date_slot: { medicineId: id, date: today, slot } } });
        const target = after.find((a) => !before.includes(a) && slotGroupOf(a) === slotGroupOf(slot));
        if (!log || !target) continue;
        const clash = await tx.doseLog.findUnique({ where: { medicineId_date_slot: { medicineId: id, date: today, slot: target } } });
        if (clash) await tx.doseLog.delete({ where: { id: log.id } });
        else await tx.doseLog.update({ where: { id: log.id }, data: { slot: target } });
      }
    });
    return toMedicineView(await this.prisma.medicine.findUniqueOrThrow({ where: { id }, include: medicineInclude }));
  }

  /** Stop a course: no dose is due from the given date on. */
  @Post(':id/schedule/stop')
  @HttpCode(200)
  async stop(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string, @Body() dto: StopDto) {
    const medicine = await this.find(userId, id);
    if (!medicine.schedule) throw new BadRequestException('This medicine has no reminders to stop');
    await this.prisma.schedule.update({ where: { medicineId: id }, data: { stoppedOn: dto.date ?? todayUtc() } });
    return toMedicineView(await this.prisma.medicine.findUniqueOrThrow({ where: { id }, include: medicineInclude }));
  }

  private async find(userId: string, id: string) {
    const medicine = await this.prisma.medicine.findFirst({ where: { id, userId }, include: { schedule: true } });
    if (!medicine) throw new NotFoundException('Medicine not found');
    return medicine;
  }
}
