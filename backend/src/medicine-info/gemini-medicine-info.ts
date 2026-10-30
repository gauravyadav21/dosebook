import { type FetchLike, geminiJson } from '../common/gemini.js';
import { cleanSummary, type LookupResult, type MedicineInfoProvider } from './medicine-info.js';

const TIMEOUT_MS = 10_000;

const PROMPT = `You are given one name. Decide whether it is the name of a medicine (generic or brand).
Return only JSON: {"isMedicine": boolean, "name": string, "usedFor": string, "storage": string}
If it is a medicine: "name" is its usual name. "usedFor" is one or two plain sentences on what it is usually prescribed for. "storage" is one or two plain sentences on how to keep it at home.
Give nothing else: no dose, amount, frequency, how to take it, side effects, warnings, interactions or advice. Do not address the reader.
If it is not a medicine: {"isMedicine": false, "name": "", "usedFor": "", "storage": ""}
Name: `;

/** Looks a medicine up with Gemini. Only the name is sent. The answer is untrusted and cleaned by cleanSummary. */
export class GeminiMedicineInfo implements MedicineInfoProvider {
  private readonly models: string[];

  constructor(
    private readonly apiKey: string,
    models: string | string[],
    private readonly fetchFn: FetchLike = fetch,
  ) {
    this.models = [models].flat();
  }

  async lookup(name: string): Promise<LookupResult | null> {
    const text = await geminiJson({
      fetchFn: this.fetchFn,
      apiKey: this.apiKey,
      models: this.models,
      parts: [{ text: `${PROMPT}${JSON.stringify(name)}` }],
      timeoutMs: TIMEOUT_MS,
    });
    if (!text) return null;
    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch {
      return null;
    }
    if (!parsed || typeof parsed !== 'object') return null;
    const result = parsed as Record<string, unknown>;
    if (result.isMedicine === false) return { isMedicine: false };
    if (result.isMedicine !== true) return null;
    // Only the two requested fields are read; anything else the model adds is ignored.
    const usedFor = cleanSummary(result.usedFor);
    const usualName = typeof result.name === 'string' ? result.name.trim().slice(0, 80) : '';
    if (!usedFor || !usualName) return null;
    return { isMedicine: true, name: usualName, usedFor, storage: cleanSummary(result.storage) };
  }
}
