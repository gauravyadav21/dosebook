import { type FetchLike, geminiJson } from '../common/gemini.js';
import type { ExtractionInput, ExtractionResult, Extractor } from './extraction.types.js';
import { normalizeExtraction } from './normalize.js';

const TIMEOUT_MS = 30_000;

const PROMPT = `You read one medical prescription and copy out what is written. Do not add, infer or correct anything.
Return only JSON with this shape:
{
  "condition": string or null,
  "date": "YYYY-MM-DD" or null,
  "doctor": { "name": string or null, "phone": string or null, "registrationNo": string or null, "specialty": string or null, "availability": string or null },
  "medicines": [ { "name": string, "dose": string or null, "frequency": string or null, "duration": string or null } ]
}
Use null for anything not clearly written. If this is not a prescription, return {"medicines": []}.`;

/**
 * Reads a prescription with Gemini (free tier). The answer is untrusted: it goes through
 * normalizeExtraction and is only ever shown to the user for review.
 */
export class GeminiExtractor implements Extractor {
  private readonly models: string[];

  constructor(
    private readonly apiKey: string,
    models: string | string[],
    private readonly fetchFn: FetchLike = fetch,
  ) {
    this.models = [models].flat();
  }

  async extract(input: ExtractionInput): Promise<ExtractionResult | null> {
    const text = await geminiJson({
      fetchFn: this.fetchFn,
      apiKey: this.apiKey,
      models: this.models,
      parts: [{ text: PROMPT }, { inline_data: { mime_type: input.mimeType, data: input.data.toString('base64') } }],
      timeoutMs: TIMEOUT_MS,
    });
    if (!text) return null;
    try {
      return normalizeExtraction(JSON.parse(text));
    } catch {
      return null;
    }
  }
}
