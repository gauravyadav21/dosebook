export interface DoctorLike {
  id: string;
  name: string;
  phone: string | null;
  registrationNo: string | null;
}

export interface DoctorInput {
  name: string;
  phone?: string;
  registrationNo?: string;
}

export type DoctorMatch =
  | { kind: 'EXACT'; doctor: DoctorLike }
  /** Only the name matches: the user must say whether it is the same doctor (S9). */
  | { kind: 'NAME_ONLY'; candidates: DoctorLike[] }
  | { kind: 'NONE' };

/** "Dr. A. Mehra" and "dr a mehra" compare equal. */
export function normalizeName(name: string): string {
  return name
    .toLowerCase()
    .replace(/[.,]/g, ' ')
    .replace(/\bdr\b/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function normalizePhone(phone: string): string {
  return phone.replace(/[^0-9+]/g, '');
}

export function normalizeRegistration(reg: string): string {
  return reg.trim().toLowerCase();
}

/**
 * Finds the existing card for a doctor named on a new prescription.
 * Same registration number, or same name and phone, is the same doctor.
 * A name match alone is never merged silently.
 */
export function matchDoctor(input: DoctorInput, existing: DoctorLike[]): DoctorMatch {
  if (input.registrationNo) {
    const reg = normalizeRegistration(input.registrationNo);
    const byReg = existing.find((d) => d.registrationNo && normalizeRegistration(d.registrationNo) === reg);
    if (byReg) return { kind: 'EXACT', doctor: byReg };
  }
  const name = normalizeName(input.name);
  const sameName = existing.filter((d) => normalizeName(d.name) === name);
  if (input.phone) {
    const phone = normalizePhone(input.phone);
    const byPhone = sameName.find((d) => d.phone && normalizePhone(d.phone) === phone);
    if (byPhone) return { kind: 'EXACT', doctor: byPhone };
  }
  return sameName.length > 0 ? { kind: 'NAME_ONLY', candidates: sameName } : { kind: 'NONE' };
}
