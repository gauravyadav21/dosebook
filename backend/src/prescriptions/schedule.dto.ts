import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, ArrayUnique, IsArray, IsEnum, IsIn, IsInt, IsOptional, Matches, Max, Min } from 'class-validator';
import { IsCalendarDate } from '../common/dates.js';
import { SLOTS, type Slot, TIME_RE } from '../common/slots.js';
import { FoodTiming } from '../generated/prisma/enums.js';

export const MAX_COURSE_DAYS = 365;
const MAX_DOSES = 12;

/** Dose schedule exactly as the user confirmed it from the prescription. The app never changes it. */
export class ScheduleDto {
  @ApiProperty({
    enum: SLOTS,
    isArray: true,
    example: ['MORNING', 'DINNER'],
    description: 'Times of day taken at their default time (morning 08:00, lunch 13:00, dinner 20:00). May be empty if times is not.',
  })
  @IsArray()
  @ArrayMaxSize(3)
  @ArrayUnique()
  @IsIn(SLOTS, { each: true })
  slots: Slot[];

  @ApiPropertyOptional({
    example: ['07:30'],
    description: 'Clock times (HH:mm) the user chose, instead of a default or as extra doses. No two doses at the same time.',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(MAX_DOSES)
  @ArrayUnique()
  @Matches(TIME_RE, { each: true, message: 'each time must be HH:mm' })
  times?: string[];

  @ApiProperty({ enum: FoodTiming })
  @IsEnum(FoodTiming)
  food: FoodTiming;

  @ApiProperty({ minimum: 1, maximum: MAX_DOSES, description: 'Equals slots plus times.' })
  @IsInt()
  @Min(1)
  @Max(MAX_DOSES)
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
