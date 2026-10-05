import {
  Body,
  ConflictException,
  Controller,
  Delete,
  Get,
  HttpCode,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  Patch,
} from '@nestjs/common';
import { ApiBearerAuth, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, Matches, MaxLength, ValidateIf } from 'class-validator';
import { UserId } from '../auth/auth.decorators.js';
import { PHONE_RE } from '../prescriptions/prescriptions.dto.js';
import { prescriptionInclude, toDoctorView, toPrescriptionView } from '../prescriptions/prescriptions.views.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { normalizeRegistration } from './doctor-match.js';
import { shareText } from './share-text.js';

/** Any field may be changed; null clears an optional field. Name cannot be cleared. */
export class UpdateDoctorDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name?: string;

  @ApiPropertyOptional({ nullable: true })
  @ValidateIf((o: UpdateDoctorDto) => o.phone !== null && o.phone !== undefined)
  @Matches(PHONE_RE, { message: 'phone must be a valid phone number' })
  phone?: string | null;

  @ApiPropertyOptional({ nullable: true })
  @ValidateIf((o: UpdateDoctorDto) => o.registrationNo !== null && o.registrationNo !== undefined)
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  registrationNo?: string | null;

  @ApiPropertyOptional({ nullable: true })
  @ValidateIf((o: UpdateDoctorDto) => o.specialty !== null && o.specialty !== undefined)
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  specialty?: string | null;

  @ApiPropertyOptional({ nullable: true })
  @ValidateIf((o: UpdateDoctorDto) => o.availability !== null && o.availability !== undefined)
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  availability?: string | null;
}

const clean = (value: string | null | undefined) => (value === undefined ? undefined : value?.trim() || null);

@ApiTags('doctors')
@ApiBearerAuth()
@Controller('doctors')
export class DoctorsController {
  constructor(private readonly prisma: PrismaService) {}

  /** One card per doctor, built from confirmed prescriptions (S9). */
  @Get()
  async list(@UserId() userId: string) {
    const rows = await this.prisma.doctor.findMany({
      where: { userId },
      include: { _count: { select: { prescriptions: true } } },
      orderBy: { name: 'asc' },
    });
    return rows.map((d) => ({ ...toDoctorView(d), prescriptionCount: d._count.prescriptions }));
  }

  /** The card with every prescription recorded against this doctor, newest first. */
  @Get(':id')
  async get(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string) {
    const doctor = await this.find(userId, id);
    const prescriptions = await this.prisma.prescription.findMany({
      where: { userId, doctorId: id },
      include: prescriptionInclude,
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
    });
    return {
      ...toDoctorView(doctor),
      prescriptionCount: prescriptions.length,
      prescriptions: prescriptions.map(toPrescriptionView),
    };
  }

  @Get(':id/share')
  async share(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string) {
    return { text: shareText(await this.find(userId, id)) };
  }

  @Patch(':id')
  async update(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateDoctorDto) {
    await this.find(userId, id);
    const registrationNo = clean(dto.registrationNo);
    if (registrationNo) {
      const others = await this.prisma.doctor.findMany({ where: { userId, id: { not: id } } });
      const taken = others.some(
        (d) => d.registrationNo && normalizeRegistration(d.registrationNo) === normalizeRegistration(registrationNo),
      );
      if (taken) throw new ConflictException('Another doctor card already has this registration number');
    }
    const row = await this.prisma.doctor.update({
      where: { id },
      data: {
        name: dto.name?.trim(),
        phone: clean(dto.phone),
        registrationNo,
        specialty: clean(dto.specialty),
        availability: clean(dto.availability),
      },
    });
    return toDoctorView(row);
  }

  /** Removes the card only. Its prescriptions stay in the timeline. */
  @Delete(':id')
  @HttpCode(204)
  async remove(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.find(userId, id);
    await this.prisma.doctor.delete({ where: { id } });
  }

  private async find(userId: string, id: string) {
    const doctor = await this.prisma.doctor.findFirst({ where: { id, userId } });
    if (!doctor) throw new NotFoundException('Doctor not found');
    return doctor;
  }
}
