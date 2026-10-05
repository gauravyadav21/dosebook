export interface ShareableDoctor {
  name: string;
  specialty: string | null;
  phone: string | null;
  registrationNo: string | null;
  availability: string | null;
}

/**
 * Text handed to the phone's share sheet. It contains the doctor's contact only:
 * never the user's conditions, medicines, documents or notes (S9).
 */
export function shareText(doctor: ShareableDoctor): string {
  const lines = [doctor.name];
  if (doctor.specialty) lines.push(doctor.specialty);
  if (doctor.phone) lines.push(`Phone: ${doctor.phone}`);
  if (doctor.registrationNo) lines.push(`Registration no.: ${doctor.registrationNo}`);
  if (doctor.availability) lines.push(`Availability: ${doctor.availability}`);
  lines.push('As printed on a prescription. Not verified.');
  return lines.join('\n');
}
