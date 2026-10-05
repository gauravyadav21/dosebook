import { dailySlots, endDateExclusive, totalDoses } from '../doses/doses.logic.js';
import type { Doctor, Medicine, Prisma, Schedule } from '../generated/prisma/client.js';

export const medicineInclude = {
  schedule: true,
  _count: { select: { doseLogs: { where: { status: 'TAKEN' } } } },
} satisfies Prisma.MedicineInclude;

export const prescriptionInclude = {
  doctor: true,
  medicines: { include: medicineInclude, orderBy: { position: 'asc' } },
} satisfies Prisma.PrescriptionInclude;

type MedicineRow = Medicine & { schedule: Schedule | null; _count: { doseLogs: number } };
type PrescriptionRow = Prisma.PrescriptionGetPayload<{ include: typeof prescriptionInclude }>;

export function toDoctorView(doctor: Doctor) {
  return {
    id: doctor.id,
    name: doctor.name,
    specialty: doctor.specialty,
    registrationNo: doctor.registrationNo,
    phone: doctor.phone,
    availability: doctor.availability,
  };
}

export function toScheduleView(schedule: Schedule | null) {
  if (!schedule) return null;
  return {
    slots: dailySlots({ ...schedule, times: [] }),
    times: [...schedule.times].sort(),
    food: schedule.food,
    dosesPerDay: schedule.dosesPerDay,
    courseDays: schedule.courseDays,
    startDate: schedule.startDate,
    endDate: endDateExclusive(schedule),
    stopped: schedule.stoppedOn !== null,
  };
}

export function toMedicineView(m: MedicineRow) {
  return {
    id: m.id,
    source: m.source,
    name: m.name,
    dose: m.dose,
    frequency: m.frequency,
    duration: m.duration,
    feedback: m.feedback,
    schedule: toScheduleView(m.schedule),
    adherence: m.schedule ? { taken: m._count.doseLogs, total: totalDoses(m.schedule) } : null,
  };
}

export function toPrescriptionView(p: PrescriptionRow) {
  const medicines = p.medicines.map(toMedicineView);
  return {
    id: p.id,
    documentId: p.documentId,
    condition: p.condition,
    date: p.date,
    doctor: p.doctor ? toDoctorView(p.doctor) : null,
    medicines,
    adherence: {
      taken: medicines.reduce((sum, m) => sum + (m.adherence?.taken ?? 0), 0),
      total: medicines.reduce((sum, m) => sum + (m.adherence?.total ?? 0), 0),
    },
  };
}
