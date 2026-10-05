import { isCalendarDate } from '../common/dates.js';
import type { ExtractedDoctor, ExtractedMedicine, ExtractionResult } from './extraction.types.js';

const MAX_TEXT = 160;
const MAX_MEDICINES = 20;

function text(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim().replace(/\s+/g, ' ');
  return trimmed ? trimmed.slice(0, MAX_TEXT) : undefined;
}

/**
 * Turns untrusted extractor output (for example model JSON) into a safe ExtractionResult.
 * Unknown fields are dropped, text is trimmed and capped, and a result without any medicine is rejected.
 */
export function normalizeExtraction(raw: unknown): ExtractionResult | null {
  if (!raw || typeof raw !== 'object') return null;
  const input = raw as Record<string, unknown>;

  const medicines: ExtractedMedicine[] = [];
  if (Array.isArray(input.medicines)) {
    for (const item of input.medicines.slice(0, MAX_MEDICINES)) {
      if (!item || typeof item !== 'object') continue;
      const m = item as Record<string, unknown>;
      const name = text(m.name);
      if (!name) continue;
      medicines.push({ name, dose: text(m.dose), frequency: text(m.frequency), duration: text(m.duration) });
    }
  }
  if (medicines.length === 0) return null;

  let doctor: ExtractedDoctor | undefined;
  if (input.doctor && typeof input.doctor === 'object') {
    const d = input.doctor as Record<string, unknown>;
    doctor = {
      name: text(d.name),
      phone: text(d.phone),
      registrationNo: text(d.registrationNo),
      specialty: text(d.specialty),
      availability: text(d.availability),
    };
  }

  const date = text(input.date);
  return {
    condition: text(input.condition),
    date: isCalendarDate(date) ? date : undefined,
    doctor,
    medicines,
  };
}
