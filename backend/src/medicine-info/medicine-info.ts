/**
 * General information about a medicine for chat lookups (S5).
 * It comes from a model the first time a medicine is asked about and is then reused from our own table.
 * It holds two facts and nothing else: what the medicine is usually prescribed for, and how to keep it.
 * No dose, no instruction. It is always shown with GENERAL_INFO_DISCLAIMER.
 */

export const GENERAL_INFO_DISCLAIMER =
  'General information from an AI model, not checked by a doctor. Not advice. Ask your doctor or pharmacist.';

export type LookupResult =
  | { isMedicine: true; name: string; usedFor: string; storage: string | null }
  /** The name is not a medicine; nothing is saved. */
  | { isMedicine: false };

export interface MedicineInfoProvider {
  /** Receives the medicine name only: never the user's message or any of their data. Null when nothing usable came back. */
  lookup(name: string): Promise<LookupResult | null>;
}

export const MEDICINE_INFO_PROVIDER = Symbol('MEDICINE_INFO_PROVIDER');

const MAX_SUMMARY = 300;

/** Anything that reads like a dose or an instruction is removed before the text is stored or shown. */
const UNSAFE_SENTENCE =
  /\b\d+(\.\d+)?\s?(mg|mcg|ml|g|iu|units?|tablets?|capsules?|drops?|times|hours?|days?)\b|\b(take|taking|you should|should be taken|dosage|dose|doses|recommended|maximum|every \w+ hours?)\b/i;

export function medicineKey(name: string): string {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
}

/** Keeps only plain descriptive sentences and caps the length. Null when nothing safe is left. */
export function cleanSummary(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const sentences = raw
    .replace(/\s+/g, ' ')
    .trim()
    .split(/(?<=[.!?])\s+/)
    .filter((s) => s && !UNSAFE_SENTENCE.test(s));
  let summary = '';
  for (const sentence of sentences) {
    if (summary.length + sentence.length + 1 > MAX_SUMMARY) break;
    summary = summary ? `${summary} ${sentence}` : sentence;
  }
  return summary || null;
}
