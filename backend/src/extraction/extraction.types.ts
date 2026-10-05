export interface ExtractedMedicine {
  name: string;
  dose?: string;
  frequency?: string;
  duration?: string;
}

export interface ExtractedDoctor {
  name?: string;
  phone?: string;
  registrationNo?: string;
  specialty?: string;
  availability?: string;
}

/** What an extractor read from a prescription. Always reviewed by the user; never saved as confirmed data. */
export interface ExtractionResult {
  condition?: string;
  date?: string;
  doctor?: ExtractedDoctor;
  medicines: ExtractedMedicine[];
}

export interface ExtractionInput {
  fileName: string;
  mimeType: string;
  data: Buffer;
}

export interface Extractor {
  /** Returns null when nothing usable could be read; the user then enters the details by hand. */
  extract(input: ExtractionInput): Promise<ExtractionResult | null>;
}

export const EXTRACTOR = Symbol('EXTRACTOR');
