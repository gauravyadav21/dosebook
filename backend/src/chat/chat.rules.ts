/**
 * Chat (S5, S8). Pure rules, no model call in this file.
 * The chat does two things: it recalls what the user took before for a symptom, and it looks up a medicine.
 * It never prescribes, it sends anything that needs a doctor's training to a doctor, and it declines everything else.
 * Wording is fixed in docs/01-requirements/what-we-do-and-dont.md.
 */

export const ESCALATION_TEXT =
  "This needs a doctor's attention. I can't prescribe or advise treatment. Please contact your doctor or emergency services.";
export const EMERGENCY_TEXT = 'In an emergency, call your local emergency number.';
export const FOOTER_TEXT =
  "I only recall your own records. I don't prescribe. Check with your doctor if anything has changed.";
export const NO_HISTORY_TEXT =
  "I don't have anything for this in your own records, and I can't suggest a medicine. Please see a doctor.";
export const DECLINED_TEXT =
  "I can do two things: show what you took before for a symptom, or look up a medicine. I can't help with anything else.";
export const DOSAGE_TEXT =
  "I can't tell you how much to take. Taking a medicine without a doctor's advice is not recommended. Please visit your doctor.";
export const PRESCRIPTION_LABEL = 'From prescription';

export type FeedbackValue = 'WORKED' | 'DID_NOT_WORK' | 'SIDE_EFFECT';

/** One medicine from the user's confirmed prescriptions. Own reminders are not part of chat. */
export interface HistoryItem {
  medicineId: string;
  name: string;
  dose: string | null;
  frequency: string | null;
  duration: string | null;
  feedback: FeedbackValue | null;
  condition: string;
  prescriber: string | null;
  date: string;
}

export type EscalationReason = 'RED_FLAG' | 'OUT_OF_SCOPE' | 'PERSISTENT' | 'ALL_BLOCKED';

export interface RecalledMedicine {
  medicineId: string;
  name: string;
  dose: string | null;
  frequency: string | null;
  duration: string | null;
  sourceLabel: string;
  prescriber: string | null;
  date: string;
  condition: string;
  /** Shown as recorded. Chat never asks for feedback; it is given on the prescription. */
  feedback: FeedbackValue | null;
}

/** The only general facts chat shows about a medicine. */
export interface GeneralInfoView {
  /** What the medicine is usually prescribed for. */
  usedFor: string;
  /** How to keep it. Null when not known. */
  storage: string | null;
  disclaimer: string;
}

export interface ChatAnswer {
  kind: 'RECALL' | 'ESCALATION' | 'NO_HISTORY' | 'MEDICINE_INFO' | 'DECLINED';
  reason?: EscalationReason | 'DOSAGE';
  text: string;
  medicines: RecalledMedicine[];
  /** Past medicines left out of a recall because of an allergy or "did not work" / "side effect" feedback. */
  excludedCount: number;
  emergency?: string;
  /** MEDICINE_INFO only. */
  medicineName?: string;
  generalInfo?: GeneralInfoView | null;
  /** MEDICINE_INFO only: the looked-up medicine matches one of the user's allergies. */
  allergyMatch?: boolean;
  footer: string;
}

/** The rules found a medicine to look up; the caller adds general information and builds the answer. */
export interface LookupRequest {
  kind: 'LOOKUP';
  name: string;
  own: HistoryItem[];
  /** True when the user clearly asked about a medicine ("what is X") or X is in their records. */
  explicit: boolean;
}

const RED_FLAGS = [
  'chest pain',
  'chest tightness',
  'trouble breathing',
  'difficulty breathing',
  'breathing difficulty',
  'hard to breathe',
  'cant breathe',
  'cannot breathe',
  'shortness of breath',
  'breathless',
  'stroke',
  'face drooping',
  'slurred speech',
  'severe bleeding',
  'bleeding heavily',
  'heavy bleeding',
  'coughing blood',
  'vomiting blood',
  'blood in',
  'high fever',
  'faint',
  'passed out',
  'unconscious',
  'seizure',
  'sudden severe',
  'severe pain',
  'worst headache',
  'swollen face',
  'swelling of the face',
  'anaphyla',
  'overdose',
  'suicid',
];

/** Requests that need a doctor's training: a new medicine, a dose or course change, interactions, diagnosis, pregnancy, a child. */
const OUT_OF_SCOPE: RegExp[] = [
  /\bpregnan/,
  /\bbreast ?feed/,
  /\b(child|children|kid|kids|baby|infant|toddler|son|daughter)\b/,
  /\b(stop|quit|discontinue)\b.*\b(course|medicine|medicines|medication|taking|tablet|tablets|antibiotic)\b/,
  /\b(new|different|another|other|stronger|better|alternative)\b.*\b(medicine|medicines|medication|drug|tablet|antibiotic)\b/,
  /\b(interact|interaction|interactions|combine|mix|alcohol)\b/,
  /\btake\b.*\b(with|together)\b/,
  /\b(diagnos\w*|what do i have|do i have|is (it|this) serious|how serious)\b/,
  /\bprescribe\b/,
  /\b(can i take|should i take)\b/,
];

/** Questions about how much or how often to take a medicine. Refused with DOSAGE_TEXT; never sent to a model. */
const DOSAGE: RegExp[] = [
  /\b(dose|doses|dosage|dosing)\b/,
  /\bhow (much|many|often)\b/,
  /\b\d+(\.\d+)?\s?(mg|mcg|ml|g|iu|units?)\b/,
  /\b(times|tablets?|pills?|capsules?|spoons?|drops?) (a|per|each|every) (day|night|week|hour)\b/,
  /\b(double|increase|raise|reduce|lower|more|extra|another|half|two|three|2|3)\b.*\b(tablets?|pills?|capsules?|spoons?|drops?)\b/,
];

export function asksDosage(message: string): boolean {
  const text = normalize(message);
  return DOSAGE.some((re) => re.test(text));
}

const PERSISTENT: RegExp[] = [
  /\b(weeks?|months?|years?)\b/,
  /\b(getting|gotten|got) worse\b/,
  /\bworsening\b/,
  /\bkeeps? coming back\b/,
  /\bcomes? back\b/,
  /\bagain and again\b/,
  /\b(not|wont|isnt) go(ing)? away\b/,
  /\bchronic\b/,
];

/** Words that mark a message as describing how the user feels. */
const SYMPTOM_CUES =
  /\b(i have|i ve|i am|im|i feel|feeling|pain|ache|aches|aching|hurts?|fever|cough|cold|sore|sick|nausea|vomit\w*|dizz\w*|rash|itch\w*|swelling|swollen|throat|headache|migraine|stomach|allerg\w*|sneez\w*|runny|blocked|congest\w*|diarr\w*|constipat\w*|cramps?|infection|flu|tired|weak)\b/;

/** "what is X", "tell me about X", "search X": the rest is treated as a medicine name. */
const LOOKUP_PHRASE =
  /^(?:what is|what s|whats|what are|tell me about|about|info on|info about|information on|information about|details of|details on|search for|search|look up|lookup|find|describe|medicine)\s+(.+)$/;

const LEADING_POLITENESS = /^(?:(?:please|pls|hi|hello|hey|can you|could you|would you|kindly)\s+)+/;

const SMALL_TALK = new Set(['hello', 'hi', 'hey', 'thanks', 'thank', 'bye', 'yes', 'no', 'okay', 'ok', 'good', 'morning', 'evening', 'night']);

const NAME_NOISE = new Set(['the', 'a', 'an', 'medicine', 'tablet', 'tablets', 'capsule', 'capsules', 'drug', 'used', 'for', 'please']);

const STOPWORDS = new Set([
  'i', 'have', 'has', 'had', 'a', 'an', 'the', 'my', 'me', 'am', 'is', 'are', 'and', 'or', 'for', 'of', 'in', 'on',
  'with', 'what', 'worked', 'work', 'did', 'do', 'take', 'took', 'last', 'time', 'before', 'again', 'got', 'get',
  'feel', 'feeling', 'some', 'bit', 'little', 'mild', 'bad', 'very', 'really', 'today', 'now', 'since', 'it', 'this',
  'that', 'when', 'can', 'you', 'tell', 'show', 'please', 'which', 'medicine', 'medicines', 'need', 'help',
]);

/** Words too general to identify a condition on their own. */
const GENERIC = new Set(['pain', 'ache', 'seasonal', 'acute', 'viral', 'infection', 'problem', 'issue', 'upper', 'lower']);

export function normalize(text: string): string {
  return text
    .toLowerCase()
    .replace(/['’]/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function tokens(text: string): string[] {
  return normalize(text)
    .split(' ')
    .filter((t) => t && !STOPWORDS.has(t))
    .map(singular);
}

/** "allergies" -> "allergy", "headaches" -> "headache". Enough for matching; not a full stemmer. */
function singular(word: string): string {
  if (word.length > 4 && word.endsWith('ies')) return `${word.slice(0, -3)}y`;
  if (word.length > 4 && word.endsWith('s')) return word.slice(0, -1);
  return word;
}

/** "N days" counts as long-lasting from a week on. */
function mentionsManyDays(text: string): boolean {
  const match = /\b(\d+)\s*days?\b/.exec(text);
  return match !== null && Number(match[1]) >= 7;
}

export function classify(message: string): EscalationReason | null {
  const text = normalize(message);
  if (RED_FLAGS.some((flag) => text.includes(flag))) return 'RED_FLAG';
  if (OUT_OF_SCOPE.some((re) => re.test(text))) return 'OUT_OF_SCOPE';
  if (PERSISTENT.some((re) => re.test(text)) || mentionsManyDays(text)) return 'PERSISTENT';
  return null;
}

/** True when the message is about the condition this medicine was prescribed for. */
export function matchesMessage(message: string, item: HistoryItem): boolean {
  const messageTokens = new Set(tokens(message));
  const joined = normalize(message).replace(/ /g, '');
  const conditionJoined = normalize(item.condition).replace(/ /g, '');
  // "head ache" matches "Headache".
  if (conditionJoined.length >= 4 && joined.includes(conditionJoined)) return true;
  const specific = tokens(item.condition).filter((t) => t.length >= 4 && !GENERIC.has(t));
  return specific.some((t) => messageTokens.has(t));
}

export function isAllergic(medicineName: string, allergies: string[]): boolean {
  const name = normalize(medicineName);
  return allergies.some((a) => {
    const allergy = normalize(a);
    return allergy.length >= 3 && (name.includes(allergy) || allergy.includes(name));
  });
}

export function isBlocked(item: HistoryItem, allergies: string[]): boolean {
  return item.feedback === 'DID_NOT_WORK' || item.feedback === 'SIDE_EFFECT' || isAllergic(item.name, allergies);
}

/** Finds the medicine a message asks about: one from the user's records, or a name after a lookup phrase. */
export function findMedicine(message: string, history: HistoryItem[]): LookupRequest | null {
  const text = normalize(message);
  const words = new Set(text.split(' '));

  const mentioned = history.find((item) => {
    const first = normalize(item.name).split(' ')[0];
    return first.length >= 4 && words.has(first);
  });
  if (mentioned) {
    const key = normalize(mentioned.name);
    return { kind: 'LOOKUP', name: mentioned.name, own: history.filter((h) => normalize(h.name) === key), explicit: true };
  }

  const phrase = LOOKUP_PHRASE.exec(text.replace(LEADING_POLITENESS, ''));
  const rest = (phrase ? phrase[1] : text).split(' ').filter((w) => !NAME_NOISE.has(w));
  // A medicine name is short. A bare message counts only when it is one or two words and not a symptom.
  const maxWords = phrase ? 4 : 2;
  if (rest.length === 0 || rest.length > maxWords) return null;
  // A bare message made of everyday words ("hello", "what is") is not a medicine name.
  if (!phrase && rest.some((w) => STOPWORDS.has(w) || SMALL_TALK.has(w))) return null;
  const name = rest.join(' ');
  if (name.length < 3 || name.length > 60 || SYMPTOM_CUES.test(name)) return null;
  return { kind: 'LOOKUP', name, own: [], explicit: phrase !== null };
}

function escalation(reason: EscalationReason, excludedCount = 0): ChatAnswer {
  return {
    kind: 'ESCALATION',
    reason,
    text: ESCALATION_TEXT,
    medicines: [],
    excludedCount,
    emergency: EMERGENCY_TEXT,
    footer: FOOTER_TEXT,
  };
}

export function dosageRefusal(): ChatAnswer {
  return { kind: 'DECLINED', reason: 'DOSAGE', text: DOSAGE_TEXT, medicines: [], excludedCount: 0, footer: FOOTER_TEXT };
}

export function declined(): ChatAnswer {
  return { kind: 'DECLINED', text: DECLINED_TEXT, medicines: [], excludedCount: 0, footer: FOOTER_TEXT };
}

function toRecalled(item: HistoryItem): RecalledMedicine {
  return {
    medicineId: item.medicineId,
    name: item.name,
    dose: item.dose,
    frequency: item.frequency,
    duration: item.duration,
    sourceLabel: PRESCRIPTION_LABEL,
    prescriber: item.prescriber,
    date: item.date,
    condition: item.condition,
    feedback: item.feedback,
  };
}

const newestFirst = (a: HistoryItem, b: HistoryItem) => b.date.localeCompare(a.date);

/**
 * Decides what to do with one message, from the user's own history and allergies.
 * Order matters: anything that needs a doctor is caught before recall or lookup.
 */
export function decide(message: string, history: HistoryItem[], allergies: string[]): ChatAnswer | LookupRequest {
  const reason = classify(message);
  if (reason === 'RED_FLAG') return escalation(reason);
  if (asksDosage(message)) return dosageRefusal();
  if (reason) return escalation(reason);

  const matched = history.filter((item) => matchesMessage(message, item));
  if (matched.length > 0) {
    const allowed = matched.filter((item) => !isBlocked(item, allergies));
    const excludedCount = matched.length - allowed.length;
    if (allowed.length === 0) return escalation('ALL_BLOCKED', excludedCount);
    const left =
      excludedCount === 0
        ? ''
        : excludedCount === 1
          ? ' One past medicine is left out because of your feedback or an allergy.'
          : ` ${excludedCount} past medicines are left out because of your feedback or an allergy.`;
    return {
      kind: 'RECALL',
      text: `Here is what your own records show for this.${left}`,
      medicines: allowed.sort(newestFirst).map(toRecalled),
      excludedCount,
      footer: FOOTER_TEXT,
    };
  }

  const lookup = findMedicine(message, history);
  if (lookup) return lookup;

  if (SYMPTOM_CUES.test(normalize(message))) {
    return { kind: 'NO_HISTORY', text: NO_HISTORY_TEXT, medicines: [], excludedCount: 0, footer: FOOTER_TEXT };
  }
  return declined();
}

/** Builds the answer to a medicine lookup. `general` is null when no general information is saved for it. */
export function medicineInfoAnswer(lookup: LookupRequest, general: GeneralInfoView | null, name: string, allergies: string[]): ChatAnswer {
  const own = [...lookup.own].sort(newestFirst);
  const records = own.length > 0 ? `Here is what your records show for ${name}.` : `${name} is not in your own records.`;
  const missing = general ? '' : ' No general information is saved for this medicine yet.';
  return {
    kind: 'MEDICINE_INFO',
    text: `${records}${missing}`,
    medicines: own.map(toRecalled),
    excludedCount: 0,
    medicineName: name,
    generalInfo: general,
    allergyMatch: isAllergic(name, allergies),
    footer: FOOTER_TEXT,
  };
}

/**
 * Last check before an answer leaves the server, whatever produced it.
 * A medicine outside the user's history, a changed name or dose, a blocked medicine in a recall,
 * a medicine list where none belongs, a missing source label or doctor-vs-app line,
 * or general information without its disclaimer turns the answer into an escalation.
 */
export function guard(candidate: ChatAnswer, history: HistoryItem[], allergies: string[], disclaimer: string): ChatAnswer {
  const byId = new Map(history.map((h) => [h.medicineId, h]));
  const listAllowed = candidate.kind === 'RECALL' || candidate.kind === 'MEDICINE_INFO';
  const valid =
    candidate.footer === FOOTER_TEXT &&
    (candidate.kind === 'RECALL' ? candidate.medicines.length > 0 : listAllowed || candidate.medicines.length === 0) &&
    (candidate.generalInfo == null ||
      (candidate.kind === 'MEDICINE_INFO' && candidate.generalInfo.disclaimer === disclaimer && candidate.generalInfo.usedFor !== '')) &&
    candidate.medicines.every((m) => {
      const item = byId.get(m.medicineId);
      return (
        item !== undefined &&
        item.name === m.name &&
        item.dose === m.dose &&
        m.sourceLabel === PRESCRIPTION_LABEL &&
        // A lookup shows the user's own record even when they marked it; a recall never offers a blocked medicine.
        (candidate.kind === 'MEDICINE_INFO' || !isBlocked(item, allergies))
      );
    });
  return valid ? candidate : escalation('OUT_OF_SCOPE');
}
