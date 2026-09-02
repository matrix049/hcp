import { env } from '../../../config/env.js';
import { LlmError } from './errors.js';
import { gemini } from './providers/gemini.js';
import { SYSTEM_PROMPT, buildGenerateUserPrompt, buildFixUserPrompt } from './prompt.js';
import { normalizeSurvey } from './schema.js';

/**
 * The provider ladder.
 *
 * Tier 1  Gemini — Google AI Studio, free tier. The engine that answers today.
 * Tier 2  the caller's keyword heuristic — not an AI at all, just pattern
 *         rules. Never removed: it is what answers when no key works, so the
 *         tool degrades in quality instead of failing outright.
 *
 * The list is what makes a second provider a one-file change: an adapter only
 * has to expose `name`, `available` and `generate({system, user, onProgress})`.
 *
 * A provider is skipped when it has no key. A provider that FAILS cascades to
 * the next one, except on `bad_request`: that means our own payload is wrong
 * and must surface rather than hide behind a working fallback.
 */
const LADDER = [gemini];

/** Which engines could run right now — surfaced on the admin review screen. */
export function llmStatus() {
  return {
    configured: LADDER.filter((p) => p.available).map((p) => p.name),
    order: LADDER.map((p) => p.name),
    enabled: env.llm.enabled,
  };
}

async function runLadder({ system, user, onProgress }) {
  const attempts = [];
  if (!env.llm.enabled) {
    return { data: null, engine: null, attempts: [{ provider: 'llm', kind: 'disabled' }] };
  }

  for (const provider of LADDER) {
    if (!provider.available) {
      attempts.push({ provider: provider.name, kind: 'no_key' });
      continue;
    }
    try {
      onProgress?.({ phase: 'provider', provider: provider.name });
      const { data, engine } = await provider.generate({ system, user, onProgress });
      return { data, engine, attempts };
    } catch (err) {
      const e = err instanceof LlmError ? err : new LlmError(provider.name, 'unknown', err.message);
      attempts.push({ provider: e.provider, kind: e.kind, message: e.message });
      onProgress?.({ phase: 'failed', provider: e.provider, kind: e.kind });
      if (!e.shouldFallback) throw e;
    }
  }
  return { data: null, engine: null, attempts };
}

/**
 * Questions per LLM call.
 *
 * Two independent reasons not to send a long document in one request:
 *  - output budget: a bilingual question with help and options costs roughly
 *    200 output tokens, so ~150 questions would exceed maxOutputTokens;
 *  - fidelity: given 100 similar questions at once the model collapses them
 *    into ~10 "types", finishes cleanly, and reports success. Measured
 *    2026-08-31 - 100 questions in, 10 out.
 * Smaller batches keep both the token budget and the count verifiable.
 */
const BATCH_SIZE = 25;

/** The model dropped or invented questions - the batch has to be redone. */
class CountMismatch extends Error {}

/**
 * One batch, with the count enforced.
 *
 * The prompt states the expected number, but a rule the model can ignore is
 * not a guarantee: the count is checked here, and a wrong count fails the
 * batch so the ladder retries it rather than silently losing questions.
 */
async function generateBatch(lines, { title, instructions, onProgress, batchLabel }) {
  const { data, engine, attempts } = await runLadder({
    system: SYSTEM_PROMPT,
    user: buildGenerateUserPrompt('', { title, instructions, lines }),
    onProgress,
  });
  if (!data) return { questions: null, title: null, engine, attempts };

  const { survey, repairs } = normalizeSurvey(data, { fallbackTitle: title });
  if (survey.questions.length !== lines.length) {
    throw new CountMismatch(
      `${batchLabel} : ${survey.questions.length} question(s) rendues pour ${lines.length} demandées`,
    );
  }
  return { questions: survey.questions, title: survey.title, engine, attempts, repairs };
}

/**
 * Generate a survey from the document's question lines.
 *
 * Returns { survey, engine, attempts, repairs } — `survey` is null when every
 * LLM tier failed, and the caller falls back to the heuristic.
 */
export async function generateWithLlm(text, { title, instructions, lines, onProgress } = {}) {
  // No structured lines (plain-text upload): keep the old whole-document call.
  if (!Array.isArray(lines) || lines.length === 0) {
    const { data, engine, attempts } = await runLadder({
      system: SYSTEM_PROMPT,
      user: buildGenerateUserPrompt(text, { title, instructions }),
      onProgress,
    });
    if (!data) return { survey: null, engine: null, attempts, repairs: [] };
    const { survey, repairs } = normalizeSurvey(data, { fallbackTitle: title });
    if (survey.questions.length === 0) {
      return { survey: null, engine, attempts: [...attempts, { provider: engine, kind: 'no_questions' }], repairs };
    }
    return { survey, engine, attempts, repairs };
  }

  const batches = [];
  for (let i = 0; i < lines.length; i += BATCH_SIZE) batches.push(lines.slice(i, i + BATCH_SIZE));

  const questions = [];
  const attempts = [];
  const repairs = [];
  let engine = null;
  let surveyTitle = null;

  for (const [index, batch] of batches.entries()) {
    const batchLabel = `Lot ${index + 1}/${batches.length}`;
    if (batches.length > 1) {
      onProgress?.({ phase: 'batch', index: index + 1, total: batches.length, size: batch.length });
    }

    let done = false;
    // One retry: a count mismatch is usually the model drifting, and asking
    // again with the same strict prompt normally lands it.
    for (let attempt = 1; attempt <= 2 && !done; attempt += 1) {
      try {
        const r = await generateBatch(batch, { title, instructions, onProgress, batchLabel });
        attempts.push(...r.attempts);
        if (!r.questions) return { survey: null, engine: null, attempts, repairs };
        questions.push(...r.questions);
        if (r.repairs?.length) repairs.push(...r.repairs);
        engine = r.engine;
        surveyTitle ??= r.title;
        done = true;
      } catch (err) {
        if (!(err instanceof CountMismatch)) throw err;
        onProgress?.({ phase: 'retry', model: batchLabel, reason: 'nombre de questions incorrect' });
        if (attempt === 2) {
          // Second failure: keep going with what the other batches produced
          // and tell the admin exactly which questions need checking.
          repairs.push(`${err.message}. Vérifiez les questions de ce lot.`);
          const r = await generateBatch(batch, { title, instructions, onProgress, batchLabel }).catch(() => null);
          if (r?.questions) questions.push(...r.questions);
          done = true;
        }
      }
    }
  }

  if (questions.length === 0) {
    return { survey: null, engine, attempts: [...attempts, { provider: engine, kind: 'no_questions' }], repairs };
  }

  // Ids are assigned per batch, so renumber across the whole survey.
  questions.forEach((q, i) => { q.id = `q_${i + 1}`; });

  return {
    survey: { title: surveyTitle ?? { fr: title ?? 'Enquête générée', ar: '' }, questions },
    engine,
    attempts,
    repairs,
  };
}

/**
 * Re-generate ONE question from an admin instruction on the review screen
 * ("question 5 should allow several answers").
 */
export async function fixQuestionWithLlm(question, instruction, documentText) {
  const { data, engine, attempts } = await runLadder({
    system: SYSTEM_PROMPT,
    user: buildFixUserPrompt(question, instruction, documentText),
  });
  if (!data) return { question: null, engine: null, attempts };

  const { survey, repairs } = normalizeSurvey(data);
  const fixed = survey.questions[0];
  if (!fixed) return { question: null, engine, attempts: [...attempts, { provider: engine, kind: 'no_questions' }] };

  // normalizeSurvey renumbers from q_1; keep the question's place in the survey.
  return { question: { ...fixed, id: question.id }, engine, attempts, repairs };
}
