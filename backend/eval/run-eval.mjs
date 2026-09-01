/**
 * Scores the survey generator against hand-written ground truth.
 *
 *   node eval/run-eval.mjs              # every sample doc, current engine
 *   node eval/run-eval.mjs --heuristic  # force the regex floor (LLM_ENABLED=false)
 *
 * Prints a mark out of 10 per document so a prompt or model change can be
 * judged against the previous run instead of by eyeballing the JSON.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import 'dotenv/config';

const here = path.dirname(fileURLToPath(import.meta.url));
const DOCS_DIR = path.resolve(here, '../../sample_docs');
const TRUTH = JSON.parse(fs.readFileSync(path.join(here, 'ground-truth.json'), 'utf8'));

if (process.argv.includes('--heuristic')) process.env.LLM_ENABLED = 'false';

const { extractText, extractQuestionLines, generateSurveyFromText } = await import(
  '../src/modules/admin/admin.service.js'
);

/** Accent- and case-insensitive, for matching French labels. */
const fold = (s) =>
  String(s ?? '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');

/** Weights sum to 10. */
const WEIGHTS = { extraction: 3, types: 3, options: 2, required: 1, bilingual: 1 };

function scoreDocument(expected, questions) {
  const used = new Set();
  const rows = [];

  for (const want of expected.questions) {
    // A good model rewrites the label ("Combien de personnes vivent..." ->
    // "Nombre de personnes du menage"), so `match` accepts alternatives and a
    // miss means the QUESTION is absent, not merely reworded.
    const needles = (Array.isArray(want.match) ? want.match : [want.match]).map(fold);
    const idx = questions.findIndex(
      (q, i) => !used.has(i) && needles.some((n) => fold(q.label?.fr).includes(n)),
    );
    if (idx === -1) {
      rows.push({ want, got: null, typeOk: false, optionsOk: false, requiredOk: false });
      continue;
    }
    used.add(idx);
    const got = questions[idx];
    const hasOptions = Array.isArray(got.options) && got.options.length >= 2;
    rows.push({
      want,
      got,
      typeOk: want.types.includes(got.type),
      optionsOk: want.options ? hasOptions : !hasOptions,
      requiredOk: Boolean(got.required) === Boolean(want.required),
    });
  }

  const found = rows.filter((r) => r.got);
  const missing = rows.length - found.length;
  const junk = questions.length - found.length; // generated but matched nothing expected

  // Extraction: F1 over expected vs produced questions.
  const precision = questions.length ? found.length / questions.length : 0;
  const recall = rows.length ? found.length / rows.length : 0;
  const f1 = precision + recall ? (2 * precision * recall) / (precision + recall) : 0;

  const frac = (predicate) => (found.length ? found.filter(predicate).length / found.length : 0);
  const bilingual = questions.length
    ? questions.filter((q) => q.label?.ar?.trim() && q.help?.ar?.trim()).length / questions.length
    : 0;

  const parts = {
    extraction: f1,
    types: frac((r) => r.typeOk),
    options: frac((r) => r.optionsOk),
    required: frac((r) => r.requiredOk),
    bilingual,
  };
  const total = Object.entries(WEIGHTS).reduce((sum, [k, w]) => sum + parts[k] * w, 0);

  return { rows, parts, total, missing, junk, precision, recall };
}

function bar(fraction, width = 20) {
  const filled = Math.round(fraction * width);
  return '█'.repeat(filled) + '·'.repeat(width - filled);
}

let grand = 0;
let docs = 0;

for (const [file, expected] of Object.entries(TRUTH)) {
  if (file.startsWith('_')) continue;
  const full = path.join(DOCS_DIR, file);
  if (!fs.existsSync(full)) {
    console.log(`SKIP ${file} (not found)`);
    continue;
  }

  const buffer = fs.readFileSync(full);
  const upload = { originalname: file, buffer };
  const text = await extractText(upload);
  // Pass the structured lines, exactly as the HTTP route does - scoring the
  // text-only path would measure something the admin never runs.
  const lines = await extractQuestionLines(upload);

  const t0 = Date.now();
  let result;
  try {
    result = await generateSurveyFromText(text, { lines });
  } catch (err) {
    console.log(`\n${'='.repeat(72)}\n${file}\n  FAILED: ${err.message}`);
    continue;
  }
  const seconds = ((Date.now() - t0) / 1000).toFixed(1);

  const questions = result.definition.pages[0].questions;
  const s = scoreDocument(expected, questions);

  console.log(`\n${'='.repeat(72)}`);
  console.log(`${file}`);
  console.log(`  engine   : ${result.engine}   (${seconds}s)`);
  console.log(`  questions: ${questions.length} produced / ${expected.questions.length} expected` +
              `   missed:${s.missing}  spurious:${s.junk}`);
  if (result.repairs?.length) {
    console.log(`  repairs  : ${result.repairs.length}`);
    for (const r of result.repairs.slice(0, 5)) console.log(`      - ${r}`);
  }
  if (result.attempts?.length) {
    console.log(`  attempts : ${result.attempts.map((a) => `${a.provider}:${a.kind}`).join(', ')}`);
  }
  console.log('');
  for (const [key, weight] of Object.entries(WEIGHTS)) {
    const f = s.parts[key];
    console.log(
      `  ${key.padEnd(11)} ${bar(f)} ${(f * weight).toFixed(2)} / ${weight}` +
      `   (${(f * 100).toFixed(0)}%)`,
    );
  }
  console.log(`  ${'─'.repeat(52)}`);
  console.log(`  SCORE       ${s.total.toFixed(1)} / 10`);

  const wrong = s.rows.filter((r) => r.got && (!r.typeOk || !r.optionsOk || !r.requiredOk));
  const absent = s.rows.filter((r) => !r.got);
  if (absent.length) {
    console.log(`\n  NOT FOUND (${absent.length}):`);
    for (const r of absent) console.log(`      "${r.want.match}"  expected ${r.want.types.join('|')}`);
  }
  if (wrong.length) {
    console.log(`\n  WRONG (${wrong.length}):`);
    for (const r of wrong) {
      const issues = [];
      if (!r.typeOk) issues.push(`type ${r.got.type} (expected ${r.want.types.join('|')})`);
      if (!r.optionsOk) issues.push(r.want.options ? 'options missing' : 'unexpected options');
      if (!r.requiredOk) issues.push(`required ${r.got.required} (expected ${r.want.required})`);
      console.log(`      ${r.got.id} "${r.got.label.fr.slice(0, 46)}"`);
      console.log(`          ${issues.join('; ')}`);
    }
  }

  grand += s.total;
  docs += 1;
}

if (docs > 1) {
  console.log(`\n${'='.repeat(72)}`);
  console.log(`OVERALL  ${(grand / docs).toFixed(1)} / 10   (mean of ${docs} documents)`);
}
