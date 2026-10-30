const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models';

export type FetchLike = (url: string, init: RequestInit) => Promise<Response>;

/**
 * A model that is retired (404), over its free quota (429) or overloaded (500, 503) is skipped for the next one.
 * So is a model that does not answer within `timeoutMs`.
 */
const TRY_NEXT_MODEL = new Set([404, 429, 500, 503]);

export interface GeminiRequest {
  fetchFn: FetchLike;
  apiKey: string;
  /** Tried in order until one answers. */
  models: string[];
  /** The `parts` of a single user turn: text and, for extraction, the file. */
  parts: unknown[];
  /** Per model. Keep models × timeout under the app's 30-second request limit. */
  timeoutMs: number;
}

/**
 * Asks Gemini for a JSON answer and returns the raw text, or null when the reply has none.
 * The key travels in a header, never in the URL. Errors carry the HTTP status only:
 * the response body may echo request details and must not reach logs.
 */
export async function geminiJson(request: GeminiRequest): Promise<string | null> {
  let lastFailure = 'status 0';
  for (const model of request.models) {
    let response: Response;
    try {
      response = await request.fetchFn(`${ENDPOINT}/${encodeURIComponent(model)}:generateContent`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': request.apiKey },
        body: JSON.stringify({
          contents: [{ parts: request.parts }],
          generationConfig: { responseMimeType: 'application/json', temperature: 0 },
        }),
        signal: AbortSignal.timeout(request.timeoutMs),
      });
    } catch {
      lastFailure = 'no answer in time';
      continue;
    }
    if (response.ok) {
      const body = (await response.json()) as { candidates?: { content?: { parts?: { text?: unknown }[] } }[] };
      const part = body.candidates?.[0]?.content?.parts?.find((p) => typeof p.text === 'string');
      return (part?.text as string | undefined) ?? null;
    }
    lastFailure = `status ${response.status}`;
    if (!TRY_NEXT_MODEL.has(response.status)) break;
  }
  throw new Error(`Gemini request failed with ${lastFailure}`);
}
