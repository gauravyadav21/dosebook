import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsBoolean,
  IsDefined,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { IsCalendarDate } from '../common/dates.js';
import { ScheduleDto } from './schedule.dto.js';

/** Digits with optional leading +, spaces, dashes and brackets; 6 to 20 characters. */
export const PHONE_RE = /^\+?[0-9][0-9 ()-]{5,19}$/;

export class DoctorDto {
  @ApiProperty({ example: 'Dr. A. Mehra' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name: string;

  @ApiPropertyOptional({ example: '+91 00000 00101' })
  @IsOptional()
  @Matches(PHONE_RE, { message: 'phone must be a valid phone number' })
  phone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  registrationNo?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  specialty?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  availability?: string;
}

export class ConfirmMedicineDto {
  @ApiProperty({ example: 'Paracetamol' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name: string;

  @ApiProperty({ example: '500 mg, 1 tablet' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  dose: string;

  @ApiPropertyOptional({ example: '3 times a day' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  frequency?: string;

  @ApiPropertyOptional({ example: '5 days' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  duration?: string;

  // ValidateNested alone accepts a missing object, so the schedule is also marked required.
  @ApiProperty({ type: ScheduleDto })
  @IsDefined()
  @ValidateNested()
  @Type(() => ScheduleDto)
  schedule: ScheduleDto;
}

export class ConfirmDto {
  @ApiProperty({ example: 'Sore throat' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  condition: string;

  @ApiProperty({ example: '2026-03-12' })
  @IsCalendarDate()
  date: string;

  @ApiProperty({ type: DoctorDto })
  @IsDefined()
  @ValidateNested()
  @Type(() => DoctorDto)
  doctor: DoctorDto;

  @ApiPropertyOptional({ description: 'Answer to "Same doctor?": link to this existing card.' })
  @IsOptional()
  @IsUUID()
  sameDoctorId?: string;

  @ApiPropertyOptional({ description: 'Answer to "Same doctor?": create a new card even though a name matches.' })
  @IsOptional()
  @IsBoolean()
  newDoctor?: boolean;

  @ApiProperty({ type: [ConfirmMedicineDto] })
  @ArrayMinSize(1)
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => ConfirmMedicineDto)
  medicines: ConfirmMedicineDto[];
}
