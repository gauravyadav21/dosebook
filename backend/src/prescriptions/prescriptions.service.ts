import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { todayUtc } from '../common/dates.js';
import { matchDoctor } from '../doctors/doctor-match.js';
import type { Doctor, Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { ConfirmDto, DoctorDto } from './prescriptions.dto.js';
import { scheduleProblem } from './schedule.rules.js';
import { prescriptionInclude, toDoctorView, toPrescriptionView } from './prescriptions.views.js';

@Injectable()
export class PrescriptionsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Saves what the user confirmed. Until this runs, nothing from an upload reaches the timeline or reminders (S2). */
  async confirm(userId: string, documentId: string, dto: ConfirmDto) {
    const doc = await this.prisma.document.findFirst({ where: { id: documentId, userId } });
    if (!doc) throw new NotFoundException('Document not found');
    if (doc.status === 'CONFIRMED') throw new ConflictException('This prescription is already confirmed');

    for (const m of dto.medicines) {
      const problem = scheduleProblem(m.schedule.slots, m.schedule.times ?? [], m.schedule.dosesPerDay);
      if (problem) throw new BadRequestException(`${m.name}: ${problem}`);
    }

    const prescription = await this.prisma.$transaction(async (tx) => {
      const doctor = await this.resolveDoctor(tx, userId, dto);
      const created = await tx.prescription.create({
        data: { userId, documentId, doctorId: doctor.id, condition: dto.condition.trim(), date: dto.date },
      });
      for (const [position, m] of dto.medicines.entries()) {
        await tx.medicine.create({
          data: {
            userId,
            prescriptionId: created.id,
            source: 'PRESCRIPTION',
            position,
            name: m.name.trim(),
            dose: m.dose.trim(),
            frequency: m.frequency?.trim() || null,
            duration: m.duration?.trim() || null,
            schedule: {
              create: {
                userId,
                slots: m.schedule.slots,
                times: m.schedule.times ?? [],
                food: m.schedule.food,
                dosesPerDay: m.schedule.dosesPerDay,
                courseDays: m.schedule.courseDays,
                startDate: m.schedule.startDate ?? todayUtc(),
              },
            },
          },
        });
      }
      await tx.document.update({ where: { id: documentId }, data: { status: 'CONFIRMED' } });
      return tx.prescription.findUniqueOrThrow({ where: { id: created.id }, include: prescriptionInclude });
    });
    return toPrescriptionView(prescription);
  }

  private async resolveDoctor(tx: Prisma.TransactionClient, userId: string, dto: ConfirmDto): Promise<Doctor> {
    const existing = await tx.doctor.findMany({ where: { userId } });

    if (dto.sameDoctorId) {
      const chosen = existing.find((d) => d.id === dto.sameDoctorId);
      if (!chosen) throw new NotFoundException('Doctor not found');
      return this.fillMissing(tx, chosen, dto.doctor);
    }

    const match = matchDoctor(dto.doctor, existing);
    if (match.kind === 'EXACT') {
      return this.fillMissing(tx, existing.find((d) => d.id === match.doctor.id) as Doctor, dto.doctor);
    }
    if (match.kind === 'NAME_ONLY' && !dto.newDoctor) {
      throw new ConflictException({
        statusCode: 409,
        code: 'DOCTOR_NAME_MATCH',
        message: 'A doctor with this name already exists. Is this the same doctor?',
        candidates: match.candidates.map((c) => toDoctorView(existing.find((d) => d.id === c.id) as Doctor)),
      });
    }
    return tx.doctor.create({
      data: {
        userId,
        name: dto.doctor.name.trim(),
        phone: dto.doctor.phone?.trim() || null,
        registrationNo: dto.doctor.registrationNo?.trim() || null,
        specialty: dto.doctor.specialty?.trim() || null,
        availability: dto.doctor.availability?.trim() || null,
      },
    });
  }

  /** A later prescription may print details the first one lacked. Existing values are never overwritten. */
  private async fillMissing(tx: Prisma.TransactionClient, doctor: Doctor, input: DoctorDto): Promise<Doctor> {
    const data: Prisma.DoctorUpdateInput = {};
    if (!doctor.phone && input.phone) data.phone = input.phone.trim();
    if (!doctor.registrationNo && input.registrationNo) data.registrationNo = input.registrationNo.trim();
    if (!doctor.specialty && input.specialty) data.specialty = input.specialty.trim();
    if (!doctor.availability && input.availability) data.availability = input.availability.trim();
    if (Object.keys(data).length === 0) return doctor;
    return tx.doctor.update({ where: { id: doctor.id }, data });
  }

  async list(userId: string) {
    const rows = await this.prisma.prescription.findMany({
      where: { userId },
      include: prescriptionInclude,
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
    });
    return rows.map(toPrescriptionView);
  }

  async get(userId: string, id: string) {
    const row = await this.prisma.prescription.findFirst({ where: { id, userId }, include: prescriptionInclude });
    if (!row) throw new NotFoundException('Prescription not found');
    return toPrescriptionView(row);
  }
}
