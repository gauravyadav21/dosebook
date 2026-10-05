import {
  asksDosage,
  type ChatAnswer,
  classify,
  decide,
  DECLINED_TEXT,
  DOSAGE_TEXT,
  ESCALATION_TEXT,
  findMedicine,
  FOOTER_TEXT,
  guard,
  type HistoryItem,
  isAllergic,
  type LookupRequest,
  matchesMessage,
  medicineInfoAnswer,
  PRESCRIPTION_LABEL,
} from './chat.rules.js';

const DISCLAIMER = 'General information. Not advice.';

const item = (overrides: Partial<HistoryItem> = {}): HistoryItem => ({
  medicineId: 'm1',
  name: 'Paracetamol',
  dose: '500 mg',
  frequency: '3 times a day',
  duration: '5 days',
  feedback: null,
  condition: 'Sore throat',
  prescriber: 'Dr. A. Mehra',
  date: '2026-03-12',
  ...overrides,
});

const answer = (message: string, history: HistoryItem[], allergies: string[] = []) => decide(message, history, allergies) as ChatAnswer;

describe('classify', () => {
  it.each([
    'I have chest pain',
    "I can't breathe properly",
    'shortness of breath since morning',
    'slurred speech and face drooping',
    'I am bleeding heavily',
    'high fever tonight',
    'I fainted',
    'sudden severe pain in my side',
  ])('flags red-flag symptoms: %s', (message) => {
    expect(classify(message)).toBe('RED_FLAG');
  });

  it.each([
    'can you prescribe something',
    'I want a different medicine',
    'is there a stronger tablet',
    'can I take this',
    'can I stop the course early',
    'I am pregnant',
    'my daughter has a cough',
    'does it interact with my other pills',
    'what do I have',
    'is this serious',
    'can I take it together with ibuprofen',
  ])('flags requests that need a doctor: %s', (message) => {
    expect(classify(message)).toBe('OUT_OF_SCOPE');
  });

  it.each([
    'cough for 2 weeks',
    'headache for months',
    'cold for 10 days',
    'it keeps coming back',
    'it is getting worse',
    "it won't go away",
  ])('flags long-lasting, worsening or recurring symptoms: %s', (message) => {
    expect(classify(message)).toBe('PERSISTENT');
  });

  it.each(['I have a sore throat', 'headache today', 'cold for 2 days', 'what worked for my allergy last time', 'what is paracetamol'])(
    'lets a plain symptom or lookup through: %s',
    (message) => {
      expect(classify(message)).toBeNull();
    },
  );
});

describe('dosage questions', () => {
  const questions = [
    'what is the dose of paracetamol',
    'paracetamol dosage',
    'how much paracetamol',
    'how many tablets of cetirizine',
    'how often can I have ibuprofen',
    'can I double the dose',
    'should I take more tablets',
    'is 500 mg of paracetamol ok',
    'paracetamol 3 times a day?',
    'can I have two tablets at once',
    'what is the right dose for my sore throat',
  ];

  it.each(questions)('recognises "%s"', (message) => {
    expect(asksDosage(message)).toBe(true);
  });

  it.each(questions)('refuses "%s" with the fixed wording, no medicines and no lookup', (message) => {
    const result = decide(message, [item()], []);
    expect(result).toEqual({ kind: 'DECLINED', reason: 'DOSAGE', text: DOSAGE_TEXT, medicines: [], excludedCount: 0, footer: FOOTER_TEXT });
  });

  it.each(['I have a sore throat', 'what is paracetamol', 'paracetamol', 'tell me about ibuprofen'])(
    'does not treat "%s" as a dosage question',
    (message) => {
      expect(asksDosage(message)).toBe(false);
    },
  );

  it('still escalates a red flag even when a dose is mentioned', () => {
    expect(decide('I took a double dose and now have chest pain', [item()], [])).toMatchObject({ kind: 'ESCALATION', reason: 'RED_FLAG' });
  });

  it('says to visit a doctor and that it is not recommended', () => {
    expect(DOSAGE_TEXT).toMatch(/not recommended/);
    expect(DOSAGE_TEXT).toMatch(/visit your doctor/);
  });
});

describe('matchesMessage', () => {
  it.each([
    ['I have a sore throat', 'Sore throat'],
    ['my throat hurts', 'Sore throat'],
    ['head ache since morning', 'Headache'],
    ['my allergies are back', 'Seasonal allergy'],
  ])('matches "%s" to condition "%s"', (message, condition) => {
    expect(matchesMessage(message, item({ condition }))).toBe(true);
  });

  it.each([
    ['I have a stomach upset', 'Sore throat'],
    ['back pain', 'Chest pain'],
    ['viral fever', 'Viral infection'],
  ])('does not match "%s" to condition "%s"', (message, condition) => {
    expect(matchesMessage(message, item({ condition }))).toBe(false);
  });
});

describe('isAllergic', () => {
  it('matches regardless of case and extra words', () => {
    expect(isAllergic('Paracetamol 500', ['paracetamol'])).toBe(true);
    expect(isAllergic('Amoxicillin', ['Penicillin'])).toBe(false);
    expect(isAllergic('Penicillin V', ['penicillin'])).toBe(true);
  });

  it('ignores allergy names too short to match safely', () => {
    expect(isAllergic('Paracetamol', ['pa'])).toBe(false);
  });
});

describe('decide: symptom recall', () => {
  it('recalls matching medicines with the source label, recorded feedback and the doctor-vs-app line', () => {
    const result = answer('sore throat', [item({ feedback: 'WORKED' }), item({ medicineId: 'm2', name: 'Cetirizine' })]);
    expect(result.kind).toBe('RECALL');
    expect(result.footer).toBe(FOOTER_TEXT);
    expect(result.medicines.map((m) => [m.name, m.sourceLabel, m.feedback])).toEqual([
      ['Paracetamol', PRESCRIPTION_LABEL, 'WORKED'],
      ['Cetirizine', PRESCRIPTION_LABEL, null],
    ]);
  });

  it('puts the newest prescription first', () => {
    const history = [item({ medicineId: 'old', date: '2025-01-01' }), item({ medicineId: 'new', date: '2026-03-12' })];
    expect(answer('sore throat', history).medicines.map((m) => m.medicineId)).toEqual(['new', 'old']);
  });

  it('leaves out blocked medicines and says how many', () => {
    const history = [item(), item({ medicineId: 'm2', name: 'Cetirizine', feedback: 'SIDE_EFFECT' })];
    const result = answer('sore throat', history);
    expect(result.medicines.map((m) => m.name)).toEqual(['Paracetamol']);
    expect(result.excludedCount).toBe(1);
    expect(result.text).toMatch(/left out/);
  });

  it('escalates when every match is blocked', () => {
    expect(answer('sore throat', [item({ feedback: 'DID_NOT_WORK' })])).toMatchObject({
      kind: 'ESCALATION',
      reason: 'ALL_BLOCKED',
      text: ESCALATION_TEXT,
      medicines: [],
    });
  });

  it('escalates red flags before looking at history or medicine names', () => {
    expect(answer('paracetamol for chest pain', [item()])).toMatchObject({ kind: 'ESCALATION', reason: 'RED_FLAG', medicines: [] });
  });

  it('says there is no history for a symptom the records do not cover', () => {
    expect(answer('I have a stomach upset', [item()])).toMatchObject({ kind: 'NO_HISTORY', medicines: [] });
  });
});

describe('decide: medicine lookup', () => {
  it('finds a medicine from the user\'s records anywhere in the message', () => {
    const history = [item(), item({ medicineId: 'm2', date: '2025-01-01', condition: 'Fever' }), item({ medicineId: 'm3', name: 'Cetirizine' })];
    const lookup = decide('when did I last have paracetamol', history, []) as LookupRequest;
    expect(lookup).toMatchObject({ kind: 'LOOKUP', name: 'Paracetamol', explicit: true });
    expect(lookup.own.map((h) => h.medicineId)).toEqual(['m1', 'm2']);
  });

  it.each([
    ['what is ibuprofen', 'ibuprofen'],
    ['What is Ibuprofen?', 'ibuprofen'],
    ['tell me about the medicine amoxicillin', 'amoxicillin'],
    ['search for vitamin d3', 'vitamin d3'],
    ['info on Calpol tablets', 'calpol'],
  ])('takes the name after a lookup phrase: "%s"', (message, name) => {
    expect(findMedicine(message, [])).toEqual({ kind: 'LOOKUP', name, own: [], explicit: true });
  });

  it('treats a bare one- or two-word message as a possible medicine name, not an explicit request', () => {
    expect(findMedicine('ibuprofen', [])).toEqual({ kind: 'LOOKUP', name: 'ibuprofen', own: [], explicit: false });
    expect(findMedicine('vitamin d3', [])).toMatchObject({ name: 'vitamin d3', explicit: false });
  });

  it.each(['headache', 'sore throat', 'what is a fever', 'write an email to my manager for me', 'ok', 'what is'])(
    'does not treat "%s" as a medicine lookup',
    (message) => {
      expect(findMedicine(message, [])).toBeNull();
    },
  );

  it('prefers symptom recall over lookup when the message matches a past condition', () => {
    expect(answer('sore throat', [item()]).kind).toBe('RECALL');
  });

  it('builds an answer from own records and general information', () => {
    const lookup = decide('paracetamol', [item({ feedback: 'SIDE_EFFECT' })], []) as LookupRequest;
    const result = medicineInfoAnswer(lookup, { usedFor: 'Pain and fever.', storage: 'Keep in a cool, dry place.', disclaimer: DISCLAIMER }, 'Paracetamol', ['paracetamol']);
    expect(result).toMatchObject({
      kind: 'MEDICINE_INFO',
      medicineName: 'Paracetamol',
      allergyMatch: true,
      generalInfo: { usedFor: 'Pain and fever.', storage: 'Keep in a cool, dry place.', disclaimer: DISCLAIMER },
      footer: FOOTER_TEXT,
    });
    expect(result.medicines[0]).toMatchObject({ name: 'Paracetamol', feedback: 'SIDE_EFFECT' });
  });

  it('says so when a medicine is in neither the records nor the saved information', () => {
    const lookup = findMedicine('what is ibuprofen', []) as LookupRequest;
    const result = medicineInfoAnswer(lookup, null, 'ibuprofen', []);
    expect(result.text).toBe('ibuprofen is not in your own records. No general information is saved for this medicine yet.');
    expect(result.medicines).toEqual([]);
    expect(result.generalInfo).toBeNull();
  });
});

describe('decide: everything else', () => {
  it.each(['tell me a joke please, a long one', 'what is the weather like today in the city', 'who won the match yesterday evening'])(
    'declines "%s"',
    (message) => {
      expect(answer(message, [item()])).toMatchObject({ kind: 'DECLINED', text: DECLINED_TEXT, medicines: [], footer: FOOTER_TEXT });
    },
  );
});

describe('guard', () => {
  const history = [item()];
  const good = answer('sore throat', history);
  const check = (candidate: ChatAnswer, allergies: string[] = []) => guard(candidate, history, allergies, DISCLAIMER);

  it('passes valid answers through unchanged', () => {
    expect(check(good)).toBe(good);
    const declinedAnswer = answer('tell me a long joke about something', history);
    expect(check(declinedAnswer)).toBe(declinedAnswer);
    const info = medicineInfoAnswer({ kind: 'LOOKUP', name: 'Paracetamol', own: history, explicit: true }, { usedFor: 'x', storage: null, disclaimer: DISCLAIMER }, 'Paracetamol', []);
    expect(check(info)).toBe(info);
  });

  const broken: [string, ChatAnswer][] = [
    ['a medicine not in the history', { ...good, medicines: [{ ...good.medicines[0], medicineId: 'invented', name: 'Amoxicillin' }] }],
    ['a changed dose', { ...good, medicines: [{ ...good.medicines[0], dose: '1000 mg' }] }],
    ['a changed name', { ...good, medicines: [{ ...good.medicines[0], name: 'Something else' }] }],
    ['a missing source label', { ...good, medicines: [{ ...good.medicines[0], sourceLabel: '' }] }],
    ['a missing doctor-vs-app line', { ...good, footer: '' }],
    ['a medicine list on an escalation', { ...good, kind: 'ESCALATION' }],
    ['a medicine list on a decline', { ...good, kind: 'DECLINED' }],
    ['a recall with no medicines', { ...good, medicines: [] }],
    ['general information on a recall', { ...good, generalInfo: { usedFor: 'x', storage: null, disclaimer: DISCLAIMER } }],
    ['general information without the disclaimer', { ...good, kind: 'MEDICINE_INFO', generalInfo: { usedFor: 'x', storage: null, disclaimer: '' } }],
    ['empty general information', { ...good, kind: 'MEDICINE_INFO', generalInfo: { usedFor: '', storage: null, disclaimer: DISCLAIMER } }],
  ];
  it.each(broken)('turns an answer with %s into an escalation', (_label, candidate) => {
    expect(check(candidate)).toMatchObject({ kind: 'ESCALATION', text: ESCALATION_TEXT, medicines: [] });
  });

  it('rejects a blocked medicine in a recall, but allows it in the user\'s own record of a lookup', () => {
    expect(check(good, ['Paracetamol'])).toMatchObject({ kind: 'ESCALATION', medicines: [] });
    const info = medicineInfoAnswer({ kind: 'LOOKUP', name: 'Paracetamol', own: history, explicit: true }, null, 'Paracetamol', ['Paracetamol']);
    expect(check(info, ['Paracetamol'])).toBe(info);
  });
});
