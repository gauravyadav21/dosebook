import type { ExtractionInput, ExtractionResult, Extractor } from './extraction.types.js';

/**
 * Stand-in used when no GEMINI_API_KEY is set. It does not read the file: it returns fixed fake data
 * for the bundled sample prescriptions, picked by file name, and nothing for any other file.
 * All people and numbers below are invented.
 */
const SAMPLES: Record<string, ExtractionResult> = {
  'sore-throat': {
    condition: 'Sore throat',
    date: '2026-03-12',
    doctor: {
      name: 'Dr. A. Mehra',
      phone: '+91 00000 00101',
      registrationNo: 'MH-00000-DEMO',
      specialty: 'General physician',
      availability: 'Mon to Sat, 10 am to 1 pm',
    },
    medicines: [
      { name: 'Paracetamol', dose: '500 mg, 1 tablet', frequency: '3 times a day', duration: '5 days' },
      { name: 'Cetirizine', dose: '10 mg, 1 tablet', frequency: 'at night', duration: '5 days' },
    ],
  },
  allergy: {
    condition: 'Seasonal allergy',
    date: '2025-12-02',
    doctor: {
      name: 'Dr. R. Iyer',
      phone: '+91 00000 00102',
      registrationNo: 'KA-00000-DEMO',
      specialty: 'Allergy specialist',
    },
    medicines: [{ name: 'Cetirizine', dose: '10 mg, 1 tablet', frequency: 'at night', duration: '7 days' }],
  },
  headache: {
    condition: 'Headache',
    date: '2025-08-18',
    doctor: { name: 'Dr. A. Mehra' },
    medicines: [{ name: 'Ibuprofen', dose: '400 mg, 1 tablet', frequency: 'when needed', duration: '3 days' }],
  },
};

export class DemoExtractor implements Extractor {
  async extract(input: ExtractionInput): Promise<ExtractionResult | null> {
    const name = input.fileName.toLowerCase();
    const key = Object.keys(SAMPLES).find((k) => name.includes(k));
    return key ? structuredClone(SAMPLES[key]) : null;
  }
}
