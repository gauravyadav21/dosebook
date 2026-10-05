import { DemoExtractor } from './demo.extractor.js';
import { GeminiExtractor } from './gemini.extractor.js';
import { normalizeExtraction } from './normalize.js';

const input = { fileName: 'scan.png', mimeType: 'image/png', data: Buffer.from('fake image bytes') };

describe('normalizeExtraction', () => {
  it('keeps known fields, trims text and drops unknown ones', () => {
    const result = normalizeExtraction({
      condition: '  Sore   throat ',
      date: '2026-03-12',
      diagnosisConfidence: 0.9,
      doctor: { name: 'Dr. A. Mehra', phone: '+91 00000 00101', homeAddress: 'x' },
      medicines: [{ name: ' Paracetamol ', dose: '500 mg', frequency: null, advice: 'take more if needed' }],
    });
    expect(result).toEqual({
      condition: 'Sore throat',
      date: '2026-03-12',
      doctor: { name: 'Dr. A. Mehra', phone: '+91 00000 00101', registrationNo: undefined, specialty: undefined, availability: undefined },
      medicines: [{ name: 'Paracetamol', dose: '500 mg', frequency: undefined, duration: undefined }],
    });
  });

  it.each([null, 'text', 42, [], {}, { medicines: [] }, { medicines: 'Paracetamol' }, { medicines: [{ dose: '500 mg' }] }])(
    'rejects output with no usable medicine: %j',
    (raw) => {
      expect(normalizeExtraction(raw)).toBeNull();
    },
  );

  it('drops a date that is not a real calendar date', () => {
    expect(normalizeExtraction({ date: '12 March', medicines: [{ name: 'A' }] })?.date).toBeUndefined();
    expect(normalizeExtraction({ date: '2026-02-30', medicines: [{ name: 'A' }] })?.date).toBeUndefined();
  });

  it('caps text length and the number of medicines', () => {
    const result = normalizeExtraction({
      medicines: Array.from({ length: 50 }, (_, i) => ({ name: `M${i}`, dose: 'x'.repeat(1000) })),
    });
    expect(result?.medicines).toHaveLength(20);
    expect(result?.medicines[0].dose).toHaveLength(160);
  });
});

describe('DemoExtractor', () => {
  it('returns fake sample data picked by file name', async () => {
    const result = await new DemoExtractor().extract({ ...input, fileName: 'My-Sore-Throat-scan.JPG' });
    expect(result?.condition).toBe('Sore throat');
  });
  it('returns nothing for any other file', async () => {
    expect(await new DemoExtractor().extract(input)).toBeNull();
  });
  it('hands out a fresh copy each time', async () => {
    const extractor = new DemoExtractor();
    const first = await extractor.extract({ ...input, fileName: 'headache.png' });
    first!.medicines[0].name = 'changed';
    const second = await extractor.extract({ ...input, fileName: 'headache.png' });
    expect(second!.medicines[0].name).toBe('Ibuprofen');
  });
});

describe('GeminiExtractor (mocked HTTP, no live call)', () => {
  const reply = (text: string, status = 200) =>
    vi.fn(async () => new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text }] } }] }), { status }));

  it('sends the file inline with the key in a header, never in the URL', async () => {
    const fetchFn = reply('{"medicines":[{"name":"Paracetamol"}]}');
    await new GeminiExtractor('test-key', 'gemini-test', fetchFn).extract(input);
    const [url, init] = fetchFn.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe('https://generativelanguage.googleapis.com/v1beta/models/gemini-test:generateContent');
    expect(url).not.toContain('test-key');
    expect((init.headers as Record<string, string>)['x-goog-api-key']).toBe('test-key');
    const body = JSON.parse(init.body as string);
    expect(body.contents[0].parts[1].inline_data).toEqual({ mime_type: 'image/png', data: input.data.toString('base64') });
    expect(body.generationConfig.responseMimeType).toBe('application/json');
  });

  it('returns the normalized result', async () => {
    const fetchFn = reply('{"condition":"Cough","medicines":[{"name":"Syrup","dose":"5 ml","extra":"ignored"}]}');
    expect(await new GeminiExtractor('k', 'm', fetchFn).extract(input)).toEqual({
      condition: 'Cough',
      date: undefined,
      doctor: undefined,
      medicines: [{ name: 'Syrup', dose: '5 ml', frequency: undefined, duration: undefined }],
    });
  });

  it.each([['not json at all'], ['{"medicines":[]}'], ['"just a string"']])('returns nothing for unusable output %s', async (text) => {
    expect(await new GeminiExtractor('k', 'm', reply(text)).extract(input)).toBeNull();
  });

  it('returns nothing when the response has no candidates', async () => {
    const fetchFn = vi.fn(async () => new Response('{}', { status: 200 }));
    expect(await new GeminiExtractor('k', 'm', fetchFn).extract(input)).toBeNull();
  });

  it('throws with the status only on an HTTP error, without echoing the response body', async () => {
    const fetchFn = vi.fn(async () => new Response('{"error":"quota exceeded for key test-key"}', { status: 429 }));
    await expect(new GeminiExtractor('test-key', 'm', fetchFn).extract(input)).rejects.toThrow('Gemini request failed with status 429');
  });
});
