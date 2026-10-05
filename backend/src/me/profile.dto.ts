import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsIn, IsNotEmpty, IsNumber, IsString, Matches, Max, MaxLength, Min, ValidateIf } from 'class-validator';
import { IsCalendarDate } from '../common/dates.js';
import { Sex } from '../generated/prisma/enums.js';
import { PHONE_RE } from '../prescriptions/prescriptions.dto.js';

export const BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'] as const;

/** Skips the other rules when the field is absent or null; null clears the stored value. */
const Optional = () => ValidateIf((_object, value) => value !== null && value !== undefined);

/**
 * The user's own record of themselves (S10). Every field is optional.
 * PUT replaces the whole profile: a field left out or sent as null is cleared.
 */
export class ProfileDto {
  @ApiPropertyOptional({ nullable: true })
  @Optional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name?: string | null;

  @ApiPropertyOptional({ nullable: true, example: '1990-05-17' })
  @Optional()
  @IsCalendarDate()
  dateOfBirth?: string | null;

  @ApiPropertyOptional({ nullable: true, enum: Sex })
  @Optional()
  @IsEnum(Sex)
  sex?: Sex | null;

  @ApiPropertyOptional({ nullable: true, minimum: 30, maximum: 272, description: 'Centimetres' })
  @Optional()
  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(30)
  @Max(272)
  heightCm?: number | null;

  @ApiPropertyOptional({ nullable: true, minimum: 1, maximum: 500, description: 'Kilograms' })
  @Optional()
  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(1)
  @Max(500)
  weightKg?: number | null;

  @ApiPropertyOptional({ nullable: true, enum: BLOOD_GROUPS })
  @Optional()
  @IsIn(BLOOD_GROUPS)
  bloodGroup?: string | null;

  @ApiPropertyOptional({ nullable: true })
  @Optional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  emergencyName?: string | null;

  @ApiPropertyOptional({ nullable: true })
  @Optional()
  @Matches(PHONE_RE, { message: 'emergencyPhone must be a valid phone number' })
  emergencyPhone?: string | null;

  // The user's own words, for example "asthma". Stored only; chat and reminders never read it.
  @ApiPropertyOptional({ nullable: true })
  @Optional()
  @IsString()
  @MaxLength(500)
  conditions?: string | null;
}
