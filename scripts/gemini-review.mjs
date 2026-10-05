// Code review by a model other than the author (per-story loop, step 4).
// Sends source files to Gemini in batches with the project's own review and security checklists
// and writes the findings to docs/04-ai/reviews/<date>-gemini-review.md.
//
// Run from the repo root with Node 20+:   node scripts/gemini-review.mjs [batch-name ...]
//
// What is sent: files under backend/src and mobile/lib only, plus the standards and story files.
// What is never sent: .env, the database, uploads, .session-archive. The free tier may train on
// what is sent, so this is for our own code with fake data only.
// The key is read from backend/.env and travels in a header; it is never printed or written.

import { readFileSync, readdirSync, statSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, relative } from 'node:path';

const ROOT = process.cwd();
const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models';
// Same rule as backend/src/common/gemini.ts: a retired, over-quota or overloaded model is skipped for the next.
const TRY_NEXT_MODEL = new Set([404, 429, 500, 503]);

function env(name) {
  const line = readFileSync(join(ROOT, 'backend/.env'), 'utf8')
    .split('\n')
    .find((l) => l.startsWith(`${name}=`));
  return line ? line.slice(name.length + 1).trim() : '';
}

const apiKey = env('GEMINI_API_KEY');
if (!apiKey) {
  console.error('GEMINI_API_KEY is not set in backend/.env');
  process.exit(1);
}
const models = [env('GEMINI_MODEL') || 'gemini-flash-latest', env('GEMINI_FALLBACK_MODEL') || 'gemini-flash-lite-latest'];

/** Source files under the given folders or files, without tests and generated code. */
function files(...paths) {
  const out = [];
  const walk = (p) => {
    const full = join(ROOT, p);
    if (statSync(full).isDirectory()) {
      for (const name of readdirSync(full).sort()) walk(join(p, name));
    } else if (/\.(ts|dart)$/.test(p) && !/\.spec\.ts$/.test(p) && !p.includes('/generated/')) {
      out.push(p);
    }
  };
  paths.forEach(walk);
  return out;
}

const story = (n) => {
  const dir = 'docs/01-requirements/stories';
  const name = readdirSync(join(ROOT, dir)).find((f) => f.startsWith(`${n}-`));
  return join(dir, name);
};

const BATCHES = [
  {
    name: 'auth',
    title: 'Sign-up, sign-in, token guard, profile, app set-up',
    stories: ['S8', 'S10'],
    files: files('backend/src/auth', 'backend/src/me', 'backend/src/common', 'backend/src/app.module.ts', 'backend/src/configure-app.ts', 'backend/src/main.ts', 'backend/src/prisma'),
  },
  {
    name: 'chat',
    title: 'Chat rules and medicine lookup',
    stories: ['S5', 'S8'],
    files: files('backend/src/chat', 'backend/src/medicine-info'),
  },
  {
    name: 'upload',
    title: 'Upload, file checks and reading a prescription',
    stories: ['S1', 'S2'],
    files: files('backend/src/documents', 'backend/src/extraction'),
  },
  {
    name: 'confirm',
    title: 'Confirm, prescriptions and timeline',
    stories: ['S2', 'S3'],
    files: files('backend/src/prescriptions'),
  },
  {
    name: 'records',
    title: 'Doses, medicines, allergies, notes, own reminders, doctors',
    stories: ['S4', 'S6', 'S7', 'S9'],
    files: files('backend/src/doses', 'backend/src/medicines', 'backend/src/allergies', 'backend/src/notes', 'backend/src/own-reminders', 'backend/src/doctors'),
  },
  {
    name: 'app',
    title: 'App: client, session, sign-in gate, intro, home, shared loader',
    stories: ['S11', 'S12'],
    files: files('mobile/lib/main.dart', 'mobile/lib/api/api.dart', 'mobile/lib/app', 'mobile/lib/features/auth', 'mobile/lib/features/home', 'mobile/lib/features/intro', 'mobile/lib/features/chat', 'mobile/lib/widgets/common.dart', 'mobile/lib/reminders'),
  },
];

const checklist = ['.claude/skills/review-diff/SKILL.md', '.claude/skills/security-check/SKILL.md', 'docs/03-standards/coding-standards.md']
  .map((p) => `--- ${p} ---\n${readFileSync(join(ROOT, p), 'utf8')}`)
  .join('\n\n');

function prompt(batch) {
  const stories = batch.stories.map((s) => `--- ${story(s)} ---\n${readFileSync(join(ROOT, story(s)), 'utf8')}`).join('\n\n');
  const code = batch.files
    .map((p) => {
      const numbered = readFileSync(join(ROOT, p), 'utf8')
        .split('\n')
        .map((line, i) => `${i + 1}: ${line}`)
        .join('\n');
      return `=== FILE ${p} ===\n${numbered}`;
    })
    .join('\n\n');
  return `You are reviewing code you did not write, for a hackathon project: a patient-side medicine app
that recalls and reminds and must never prescribe. Stack: NestJS + Prisma + PostgreSQL backend, Flutter app.
Another AI model wrote this code. Your job is to find real faults, not to praise it.

Follow these project checklists and standards:

${checklist}

Acceptance criteria the code must meet:

${stories}

Review the files below (each line is prefixed with its line number). Report only what you can point to in
these files: bugs, behaviour that breaks an acceptance criterion, missing validation or authorization,
ways one user could reach another user's data, personal data in logs or error messages, anything that
could make the app give medical advice, race conditions, and unhandled failures. Do not report style
points a linter covers. Do not guess about files you were not shown; if a fault depends on a file you
cannot see, say so in "why". If you find nothing, return an empty list.

Answer with JSON only, in this shape:
{"findings":[{"file":"path","line":123,"severity":"high|medium|low","title":"short name",
"why":"what goes wrong and how to trigger it","fix":"suggested change"}]}

${code}`;
}

async function ask(text) {
  let lastStatus = 0;
  for (const model of models) {
    const response = await fetch(`${ENDPOINT}/${encodeURIComponent(model)}:generateContent`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify({
        contents: [{ parts: [{ text }] }],
        generationConfig: { responseMimeType: 'application/json', temperature: 0 },
      }),
      signal: AbortSignal.timeout(180_000),
    });
    if (response.ok) {
      const body = await response.json();
      const part = body.candidates?.[0]?.content?.parts?.find((p) => typeof p.text === 'string');
      return { model, text: part?.text ?? null };
    }
    // Status only: the response body may echo request details.
    lastStatus = response.status;
    if (!TRY_NEXT_MODEL.has(response.status)) break;
  }
  return { model: null, status: lastStatus, text: null };
}

const wanted = process.argv.slice(2);
const batches = wanted.length ? BATCHES.filter((b) => wanted.includes(b.name)) : BATCHES;
const date = new Date().toISOString().slice(0, 10);
const cell = (s) => String(s ?? '').replace(/\|/g, '\\|').replace(/\s*\n\s*/g, ' ');

let md = `# Gemini review, ${date}

Review by a model other than the author, run with \`node scripts/gemini-review.mjs\`.
Prompt: the project's \`review-diff\` and \`security-check\` skills, the coding standards and the stories' acceptance criteria.
The findings below are the reviewer's words, unedited. The triage (which are real) is in the section after them.

`;

for (const batch of batches) {
  const text = prompt(batch);
  process.stdout.write(`${batch.name}: ${batch.files.length} files, ${Math.round(text.length / 1000)} thousand characters ... `);
  const answer = await ask(text);
  md += `## ${batch.name}: ${batch.title}\nStories: ${batch.stories.join(', ')}. Files sent (${batch.files.length}): ${batch.files.map((f) => `\`${relative('.', f)}\``).join(', ')}.\n\n`;
  if (!answer.text) {
    console.log(`no answer (status ${answer.status ?? 'none'})`);
    md += `**Not reviewed:** the request failed with status ${answer.status ?? 'none'} on every model tried.\n\n`;
    continue;
  }
  let findings;
  try {
    findings = JSON.parse(answer.text).findings ?? [];
  } catch {
    console.log('answer was not valid JSON');
    md += `Model: \`${answer.model}\`. **The answer was not valid JSON**; raw text:\n\n\`\`\`\n${answer.text.slice(0, 4000)}\n\`\`\`\n\n`;
    continue;
  }
  console.log(`${findings.length} findings (${answer.model})`);
  md += `Model: \`${answer.model}\`. Findings: ${findings.length}.\n\n`;
  if (findings.length) {
    md += '| # | Severity | Where | Finding | Why | Suggested fix |\n|---|---|---|---|---|---|\n';
    findings.forEach((f, i) => {
      md += `| ${batch.name}-${i + 1} | ${cell(f.severity)} | \`${cell(f.file)}:${cell(f.line)}\` | ${cell(f.title)} | ${cell(f.why)} | ${cell(f.fix)} |\n`;
    });
    md += '\n';
  }
}

mkdirSync(join(ROOT, 'docs/04-ai/reviews'), { recursive: true });
const out = `docs/04-ai/reviews/${date}-gemini-review.md`;
writeFileSync(join(ROOT, out), md);
console.log(`written: ${out}`);
