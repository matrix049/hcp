import bcrypt from 'bcryptjs';
import mammoth from 'mammoth';

import { query } from '../../db/pool.js';
import { generateWithLlm } from './llm/index.js';
import { normalizeSurvey, toSurveyDefinition } from './llm/schema.js';

/**
 * ADMIN — survey generation pipeline.
 *
 *   file (.docx/.txt)  →  extractText()      [STEP 1: parsing library, NOT AI]
 *                      →  splitIntoQuestions()[STEP 2: deterministic split]
 *                      →  generateSurvey()    [STEP 3: build the app's survey JSON]
 *                      →  publishSurvey()     [STEP 4: save to PostgreSQL]
 *
 * STEP 3 runs the LLM ladder (`./llm/`): Claude -> Gemini -> this file's regex
 * `classifyQuestion()` heuristic as the floor. The heuristic is deliberately
 * kept: it is what answers when no API key works, so the tool degrades in
 * quality instead of failing outright.
 */

// --- STEP 1: extract plain text from the uploaded file (deterministic) ---
export async function extractText(file) {
  const name = (file.originalname || '').toLowerCase();
  if (name.endsWith('.docx')) {
    const { value } = await mammoth.extractRawText({ buffer: file.buffer });
    return value;
  }
  // .txt / .md / .csv / anything plain-text
  return file.buffer.toString('utf8');
}

/**
 * The document's real question lines, with titles and section headings removed.
 *
 * A .docx knows which paragraphs are headings, so use that structure instead of
 * guessing from the words: it is the difference between "Section A -
 * Identification" being dropped and it becoming a text question. Plain-text
 * uploads have no structure, so they fall back to the wording rules below.
 */
export async function extractQuestionLines(file) {
  const name = (file.originalname || '').toLowerCase();
  if (!name.endsWith('.docx')) {
    return splitIntoQuestions(file.buffer.toString('utf8'));
  }

  // Word's "Title" and "Subtitle" styles are plain paragraphs to mammoth by
  // default, so the document's own title arrived as question 1. Map them to
  // headings and the heading rule below removes them. The style map is
  // mammoth's SECOND argument - passing it inside the input object is silently
  // ignored. French style names are included for documents authored in Word FR.
  const { value: html } = await mammoth.convertToHtml(
    { buffer: file.buffer },
    {
      styleMap: [
        "p[style-name='Title'] => h1",
        "p[style-name='Subtitle'] => h2",
        "p[style-name='Titre'] => h1",
        "p[style-name='Sous-titre'] => h2",
      ],
    },
  );
  const lines = [];
  const block = /<(h[1-6]|p)[^>]*>([\s\S]*?)<\/\1>/gi;
  let m;
  while ((m = block.exec(html)) !== null) {
    const [, tag, inner] = m;
    if (tag.toLowerCase() !== 'p') continue; // a heading is never a question

    // A paragraph that is entirely italic is an instruction to the surveyor
    // ("Document de travail...", "Questionnaire destine aux enqueteurs"),
    // not something to answer.
    if (/^\s*<em>[\s\S]*<\/em>\s*$/i.test(inner)) continue;

    const text = inner
      .replace(/<[^>]+>/g, '')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&nbsp;/g, ' ')
      .replace(/&#(\d+);/g, (_, d) => String.fromCharCode(Number(d)))
      .trim();
    if (text) lines.push(text);
  }
  return cleanQuestionLines(lines);
}

/** Strip numbering and drop anything that does not read like a question. */
function cleanQuestionLines(lines) {
  return lines
    .map((line) => line.trim())
    // strip leading numbering: "1." "1)" "1-" "Q1:" "Q1."
    .map((line) => line.replace(/^\s*(?:q\s*)?\d+\s*[.)\-:]\s*/i, '').trim())
    .filter((line) => line.length > 3)
    .filter((line) => !isHeadingLike(line));
}

/**
 * Wording-only heading detection, for plain-text uploads where no structure
 * exists. Deliberately conservative - a false positive silently deletes a
 * question, which is worse than letting one heading through.
 */
function isHeadingLike(line) {
  // "Section A - Identification", "I. Renseignements generaux", "II - Emploi"
  if (/^(section|partie|module|chapitre)\b/i.test(line)) return true;
  if (/^[IVX]{1,5}\s*[.)\-]/.test(line)) return true;
  // A short line with no question mark, no colon and no verb-like ending is a
  // label rather than a question ("Identification", "Menage").
  const words = line.split(/\s+/).length;
  if (words <= 2 && !/[?:]/.test(line)) return true;
  return false;
}

// --- STEP 2: split raw text into individual question lines ---
export function splitIntoQuestions(text) {
  return cleanQuestionLines(text.split(/\r?\n/));
}

// --- STEP 3: build the survey JSON the Flutter app expects ---
export function generateSurvey(questions, meta = {}) {
  const surveyId = meta.id || `survey_generated_${meta.stamp || 'draft'}`;
  const title = meta.title || 'Enquête générée';

  const builtQuestions = questions.map((raw, i) => {
    const { type, options, label, required } = classifyQuestion(raw);
    const q = {
      id: `q_${i + 1}`,
      type,
      label: { fr: label },
      required,
    };
    if (options) q.options = options;
    if (type === 'number') q.validation = { min: 0 };
    if (type === 'text') q.multiline = true;
    return q;
  });

  return {
    id: surveyId,
    version: 1,
    title: { fr: title },
    locales: ['fr'],
    pages: [
      {
        id: 'page_1',
        title: { fr: title },
        questions: builtQuestions,
      },
    ],
  };
}

/**
 * PLACEHOLDER heuristic — decides a question's type from its wording.
 * To be replaced by an LLM call. Returns { type, options?, label }.
 */
function classifyQuestion(rawInput) {
  // "(facultatif)" / "optionnel" is an instruction about the FIELD, not part of
  // the question text - honour it and strip it, or every generated survey
  // forces the surveyor to fill a free-comments box.
  const optional = /\(?\s*(facultatif|optionnel|non obligatoire)\s*\)?/i.test(rawInput);
  const raw = rawInput
    .replace(/\(?\s*(facultatif|optionnel|non obligatoire)\s*\)?/gi, '')
    .replace(/[\s\-–—:]+$/, '')
    .trim();
  const required = !optional;
  // Fold accents before matching: a word boundary next to an accented letter
  // does not behave like one for ASCII patterns, so "age" written with its
  // accent never matched /\bage\b/ and ages came out as free text.
  const text = raw
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');

  // 1) Explicit options: "(a / b / c)" or "... : a / b / c"
  const paren = raw.match(/\(([^)]*\/[^)]*)\)/);
  const colon = raw.match(/:\s*([^:]*\/[^:]*)$/);
  const optSource = paren?.[1] || colon?.[1];
  if (optSource) {
    const values = optSource
      .split('/')
      .map((v) => v.trim())
      .filter(Boolean);
    const label = raw.replace(paren?.[0] || colon?.[0] || '', '').replace(/[:?]\s*$/, '').trim();
    const multiple = /plusieurs|multiple|coch/.test(text);
    return {
      type: multiple ? 'checkbox' : values.length > 3 ? 'dropdown' : 'radio',
      label: label || raw,
      required,
      options: values.map((v) => ({ value: slug(v), label: { fr: v } })),
    };
  }

  // 2) Yes/No questions
  if (/\boui\b|\bnon\b|\byes\b|\bno\b|est-ce que|avez-vous|a-t-il|as-tu/.test(text)) {
    return {
      type: 'radio',
      label: raw,
      required,
      options: [
        { value: 'oui', label: { fr: 'Oui' } },
        { value: 'non', label: { fr: 'Non' } },
      ],
    };
  }

  // 3) Multi-answer wording, but the document never listed the choices. The
  //    heuristic cannot invent them, so leave it as free text rather than let
  //    the numeric rule below claim it because the sentence says "revenu".
  if (/plusieurs (reponses|choix)|cochez|multiple/.test(text)) {
    return { type: 'text', label: raw, required };
  }

  // 4) Numeric
  if (/combien|nombre|\bage\b|revenu|montant|salaire|number|how many|quantit/.test(text)) {
    return { type: 'number', label: raw, required };
  }

  // 4) Date
  if (/\bdate\b|quand|jour de/.test(text)) {
    return { type: 'date', label: raw, required };
  }

  // 5) GPS / location
  if (/gps|localisation|coordonn|position/.test(text)) {
    return { type: 'gps', label: raw, required };
  }

  // 6) Default: free text
  return { type: 'text', label: raw, required };
}

function slug(s) {
  return s
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 40) || 'opt';
}

// --- STEP 4: persist a validated survey so the app can download it ---
export async function publishSurvey(definition) {
  const title = definition.title?.fr ?? definition.title?.en ?? definition.id;
  await query(
    `INSERT INTO surveys (id, title, version, definition, is_active)
     VALUES ($1, $2, $3, $4, true)
     ON CONFLICT (id)
     DO UPDATE SET title = EXCLUDED.title,
                   version = EXCLUDED.version,
                   definition = EXCLUDED.definition,
                   is_active = true,
                   updated_at = now()`,
    [definition.id, title, definition.version ?? 1, definition],
  );
  return { id: definition.id, title };
}

// ===================== SURVEY MANAGEMENT =====================

/** All surveys (active AND inactive) for the admin list. */
export async function listAllSurveys() {
  const { rows } = await query(
    `SELECT id, title, version, is_active, updated_at
       FROM surveys ORDER BY updated_at DESC`,
  );
  return rows.map((r) => ({
    id: r.id,
    title: r.title,
    version: r.version,
    isActive: r.is_active,
    updatedAt: r.updated_at,
  }));
}

/** Show / hide a survey from the agents' download list. */
export async function setSurveyActive(id, isActive) {
  const { rowCount } = await query(
    `UPDATE surveys SET is_active = $2, updated_at = now() WHERE id = $1`,
    [id, !!isActive],
  );
  return rowCount > 0;
}

// ===================== AGENT MANAGEMENT =====================

/** All agents (no password hash). */
export async function listAgents() {
  const { rows } = await query(
    `SELECT id, matricule, first_name, last_name, role, region, phone, created_at
       FROM agents ORDER BY matricule`,
  );
  return rows.map((r) => ({
    id: r.id,
    matricule: r.matricule,
    firstName: r.first_name,
    lastName: r.last_name,
    role: r.role,
    region: r.region,
    phone: r.phone,
    createdAt: r.created_at,
  }));
}

/** Create an agent. Password is required and stored hashed. */
export async function createAgent(a) {
  const hash = await bcrypt.hash(a.password, 10);
  const { rows } = await query(
    `INSERT INTO agents (matricule, first_name, last_name, role, region, phone, password_hash)
     VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
    [a.matricule, a.firstName, a.lastName, a.role || 'agent', a.region, a.phone || null, hash],
  );
  return { id: rows[0].id };
}

/** Update an agent's fields; password only if a new one is provided. */
export async function updateAgent(id, a) {
  const hash = a.password ? await bcrypt.hash(a.password, 10) : null;
  const { rowCount } = await query(
    `UPDATE agents SET
        first_name = $2, last_name = $3, role = $4, region = $5, phone = $6,
        password_hash = COALESCE($7, password_hash)
      WHERE id = $1`,
    [id, a.firstName, a.lastName, a.role || 'agent', a.region, a.phone || null, hash],
  );
  return rowCount > 0;
}

// ===================== STEP 3 ORCHESTRATION (LLM -> heuristic) =====================

/**
 * Turn raw document text into a reviewable survey definition.
 *
 * Tries the LLM ladder first; falls back to the regex heuristic when every
 * tier is unavailable, so the admin tool always returns something.
 *
 * Nothing is saved here — the admin reviews the result and calls publish.
 * Returns { definition, engine, quality, repairs, attempts }.
 */
export async function generateSurveyFromText(text, { title, id, onProgress, lines, instructions } = {}) {
  // `lines` comes from the document's structure (headings already removed) when
  // the caller has the file; text-only callers fall back to wording rules.
  const questionLines = lines ?? splitIntoQuestions(text);
  if (questionLines.length === 0) {
    const err = new Error('No questions found in the file.');
    err.status = 400;
    throw err;
  }

  const llm = await generateWithLlm(text, { title, instructions, lines: questionLines, onProgress });
  if (llm.survey) {
    const repairs = [...llm.repairs];
    // Second safety net behind the provider's own truncation check: the model
    // can also stop cleanly having simply skipped part of a long document.
    // `questionLines` over-counts (it includes section headings), so only a
    // wide gap is worth flagging - and it warns the admin rather than blocking,
    // because a document really can be mostly headings.
    if (llm.survey.questions.length < questionLines.length * 0.5) {
      repairs.push(
        `Attention : ${llm.survey.questions.length} question(s) extraite(s) pour ` +
          `${questionLines.length} ligne(s) dans le document. Verifiez qu'aucune question ne manque.`,
      );
    }
    return {
      definition: toSurveyDefinition(llm.survey, { id }),
      engine: llm.engine,
      quality: 'ai',
      repairs,
      attempts: llm.attempts,
    };
  }

  // Floor: keyword rules. Weaker output, but never a dead end.
  const heuristic = generateSurvey(questionLines, { title, stamp: Date.now() });
  const { survey, repairs } = normalizeSurvey(
    { title: heuristic.title, questions: heuristic.pages[0].questions },
    { fallbackTitle: title },
  );
  return {
    definition: toSurveyDefinition(survey, { id }),
    engine: 'heuristic',
    quality: 'fallback',
    repairs,
    attempts: llm.attempts,
  };
}
