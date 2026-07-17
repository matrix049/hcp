import bcrypt from 'bcryptjs';
import mammoth from 'mammoth';

import { query } from '../../db/pool.js';

/**
 * ADMIN — survey generation pipeline.
 *
 *   file (.docx/.txt)  →  extractText()      [STEP 1: parsing library, NOT AI]
 *                      →  splitIntoQuestions()[STEP 2: deterministic split]
 *                      →  generateSurvey()    [STEP 3: build the app's survey JSON]
 *                      →  publishSurvey()     [STEP 4: save to PostgreSQL]
 *
 * STEP 3 currently uses a lightweight heuristic classifier. This is the single
 * place the LLM plugs in next: replace `classifyQuestion()` with a call that
 * sends each question (in batches, in parallel) to the model and returns its
 * type + options. The rest of the pipeline stays exactly the same.
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

// --- STEP 2: split raw text into individual question lines ---
export function splitIntoQuestions(text) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    // strip leading numbering: "1." "1)" "1-" "Q1:" "Q1."
    .map((line) => line.replace(/^\s*(?:q\s*)?\d+\s*[.)\-:]\s*/i, '').trim())
    .filter((line) => line.length > 3);
}

// --- STEP 3: build the survey JSON the Flutter app expects ---
export function generateSurvey(questions, meta = {}) {
  const surveyId = meta.id || `survey_generated_${meta.stamp || 'draft'}`;
  const title = meta.title || 'Enquête générée';

  const builtQuestions = questions.map((raw, i) => {
    const { type, options, label } = classifyQuestion(raw); // ← LLM plugs in here
    const q = {
      id: `q_${i + 1}`,
      type,
      label: { fr: label },
      required: true,
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
function classifyQuestion(raw) {
  const text = raw.toLowerCase();

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
      options: values.map((v) => ({ value: slug(v), label: { fr: v } })),
    };
  }

  // 2) Yes/No questions
  if (/\boui\b|\bnon\b|\byes\b|\bno\b|est-ce que|avez-vous|a-t-il|as-tu/.test(text)) {
    return {
      type: 'radio',
      label: raw,
      options: [
        { value: 'oui', label: { fr: 'Oui' } },
        { value: 'non', label: { fr: 'Non' } },
      ],
    };
  }

  // 3) Numeric
  if (/combien|nombre|\bâge\b|\bage\b|revenu|montant|salaire|number|how many|quantit/.test(text)) {
    return { type: 'number', label: raw };
  }

  // 4) Date
  if (/\bdate\b|quand|jour de/.test(text)) {
    return { type: 'date', label: raw };
  }

  // 5) GPS / location
  if (/gps|localisation|coordonn|position/.test(text)) {
    return { type: 'gps', label: raw };
  }

  // 6) Default: free text
  return { type: 'text', label: raw };
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
