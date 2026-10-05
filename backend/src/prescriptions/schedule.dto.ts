import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, ArrayNotEmpty, ArrayUnique, IsEnum, IsIn, IsInt, IsOptional, Max, Min } from 'class-validator';
import { IsCalendarDate } from '../common/dates.js';
import { SLOTS, type Slot } from '../common/slots.js';
import { FoodTiming } from '../generated/prisma/enums.js';

export const MAX_COURSE_DAYS = 365;

/** Dose schedule exactly as the user confirmed it from the prescription. The app never changes it. */
export class ScheduleDto {
  @ApiProperty({ enum: SLOTS, isArray: true, example: ['MORNING', 'NOON', 'NIGHT'] })
  @ArrayNotEmpty()
  @ArrayMaxSize(4)
  @ArrayUnique()
  @IsIn(SLOTS, { each: true })
  slots: Slot[];

  @ApiProperty({ enum: FoodTiming })
  @IsEnum(FoodTiming)
  food: FoodTiming;

  @ApiProperty({ minimum: 1, maximum: 4 })
  @IsInt()
  @Min(1)
  @Max(4)
  dosesPerDay: number;

  @ApiProperty({ minimum: 1, maximum: MAX_COURSE_DAYS })
  @IsInt()
  @Min(1)
  @Max(MAX_COURSE_DAYS)
  courseDays: number;

  @ApiPropertyOptional({ example: '2026-10-04', description: "First day of the course in the user's local date. Defaults to today (UTC)." })
  @IsOptional()
  @IsCalendarDate()
  startDate?: string;
}
