import { env } from '../../../../config/env.js';
import { SURVEY_SCHEMA } from '../schema.js';
import { LlmError } from '../errors.js';

const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models';

/**
 * Google AI Studio (Gemini) — the free tier.
 *
 * Two reasons this always streams (`streamGenerateContent`), even though the
 * answer is only used once complete:
 *   1. progress — the admin waits minutes on a busy free tier, so we report
 *      each question as it arrives instead of showing a frozen spinner;
 *   2. no request timeout — a long generation never sits silent long enough
 *      for an intermediary to cut the connection.
 *
 * The free tier meters quota PER MODEL and returns 429 / "high demand" often
 * enough that no single model is usable alone, so we rotate.
 */

/**
 * Ordered by MEASURED availability, not by how good a model looks on paper.
 *
 * The fashionable models are the contended ones. Probed 2026-08-31: every
 * flagship (3.5-flash, 3.6-flash, 2.5-flash, pro-latest) returned 429 or timed
 * out, while the older lite models answered in ~5s and still scored 9.7/10 on
 * the eval. A brilliant model that refuses the request is worth zero, so the
 * reliably available ones go first and the big ones are the fallback.
 *
 * Re-measure with: node eval/probe-models.mjs
 */
const MODELS = [
  'gemini-3.1-flash-lite',
  'gemini-3.1-flash-lite-preview',
  'gemini-3.5-flash',
  'gemini-3.6-flash',
  'gemini-2.5-flash',
];

/** Gemini's schema dialect is an OpenAPI subset — it rejects unknown keywords. */
function toGeminiSchema(schema) {
  if (Array.isArray(schema)) return schema.map(toGeminiSchema);
  if (schema && typeof schema === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(schema)) {
      if (k === 'additionalProperties') continue;
      out[k] = toGeminiSchema(v);
    }
    return out;
  }
  return schema;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * The free tier allows 20 requests per MINUTE. Google says exactly how long to
 * wait ("Please retry in 59.98s" / a RetryInfo detail), so honour it instead of
 * guessing. Returns milliseconds, or null when the response says nothing.
 */
function retryDelayMs(errorBody) {
  const info = errorBody?.error?.details?.find((d) => String(d['@type']).includes('RetryInfo'));
  const fromDetail = info?.retryDelay && /^([\d.]+)s$/.exec(info.retryDelay);
  if (fromDetail) return Math.ceil(parseFloat(fromDetail[1]) * 1000);
  const fromText = /retry in ([\d.]+)s/i.exec(errorBody?.error?.message ?? '');
  if (fromText) return Math.ceil(parseFloat(fromText[1]) * 1000);
  return null;
}

/** Questions completed so far — each question object carries exactly one "id". */
const countQuestions = (partial) => (partial.match(/"id"\s*:/g) ?? []).length;

/**
 * The label of the question currently being written, for the progress line.
 *
 * Picking the last "fr" in the buffer would show help text, and the last
 * "label" would show an option's label — both are nested inside the question.
 * So: take everything after the most recent "id" (the start of a question) and
 * read the FIRST label there, which is the question's own.
 */
function latestLabel(partial) {
  const lastId = partial.lastIndexOf('"id"');
  if (lastId === -1) return null;
  const match = /"label"\s*:\s*\{\s*"fr"\s*:\s*"((?:[^"\\]|\\.)*)"/.exec(partial.slice(lastId));
  if (!match) return null;
  try {
    // The match ends at the closing quote of the fr value, so close the two
    // objects it opened to make it parseable on its own.
    return JSON.parse('{' + match[0] + '}}').label.fr;
  } catch {
    return null;
  }
}

/** Thrown when a stream opens, produces some output, then goes quiet. */
class StallError extends Error {}

/**
 * Read one SSE stream, accumulating the JSON text and reporting progress.
 * Returns { text, finishReason }.
 *
 * A busy free tier does not usually refuse — it accepts the request, streams a
 * few questions, then stops sending anything at all. Without a stall timer the
 * only bound is the overall request timeout, so a dead connection costs a
 * minute or more that another model could have used. Any gap longer than
 * `stallMs` between chunks abandons this attempt.
 */
async function readStream(res, onProgress, model, stallMs) {
  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let text = '';
  let finishReason = null;
  let reported = 0;

  for (;;) {
    let timer;
    const stalled = new Promise((_, reject) => {
      timer = setTimeout(() => reject(new StallError('no data for ' + stallMs + 'ms')), stallMs);
    });

    let done;
    let value;
    try {
      ({ done, value } = await Promise.race([reader.read(), stalled]));
    } finally {
      clearTimeout(timer);
    }

    if (done) break;
    buffer += decoder.decode(value, { stream: true });

    // Frames are separated by a blank line, but Gemini ends its lines with
    // CRLF: splitting on '\n\n' alone matches nothing, the buffer never
    // yields a frame, and the whole stream reads back as empty.
    const frames = buffer.split(/\r?\n\r?\n/);
    buffer = frames.pop() ?? '';

    for (const frame of frames) {
      const line = frame.split(/\r?\n/).find((l) => l.startsWith('data:'));
      if (!line) continue;
      const payload = line.slice(5).trim();
      if (!payload || payload === '[DONE]') continue;

      let chunk;
      try {
        chunk = JSON.parse(payload);
      } catch {
        continue; // partial frame; the next read completes it
      }
      const candidate = chunk.candidates?.[0];
      text += candidate?.content?.parts?.[0]?.text ?? '';
      if (candidate?.finishReason) finishReason = candidate.finishReason;

      const soFar = countQuestions(text);
      if (onProgress && soFar > reported) {
        reported = soFar;
        onProgress({ phase: 'generating', model, questions: soFar, label: latestLabel(text) });
      }
    }
  }
  return { text, finishReason };
}

export const gemini = {
  name: 'gemini',
  get available() {
    return Boolean(env.llm.googleApiKey);
  },

  async generate({ system, user, onProgress }) {
    if (!this.available) throw new LlmError('gemini', 'no_key', 'GOOGLE_API_KEY is not set');

    const body = {
      systemInstruction: { parts: [{ text: system }] },
      contents: [{ role: 'user', parts: [{ text: user }] }],
      generationConfig: {
        responseMimeType: 'application/json',
        responseSchema: toGeminiSchema(SURVEY_SCHEMA),
        temperature: 0,
        // A 20-question bilingual survey with help text runs long, and the
        // default cap truncates it mid-array (see the finishReason check).
        maxOutputTokens: 32768,
      },
    };

    let last;
    const deadline = Date.now() + env.llm.deadlineMs;
    // Retry-after values collected from models that returned 429 this pass.
    let quotaDelays = [];

    for (let pass = 1; pass <= 2; pass += 1) {
      // Second pass only happens when EVERY model was rate-limited on the
      // first: then, and only then, is waiting out the window worthwhile.
      if (pass === 2) {
        if (quotaDelays.length < MODELS.length) break;
        const waitMs = Math.min(...quotaDelays);
        if (waitMs > env.llm.maxQuotaWaitMs || Date.now() + waitMs >= deadline) break;
        onProgress?.({
          phase: 'waiting',
          reason: 'quota du palier gratuit atteint sur tous les modeles',
          seconds: Math.ceil(waitMs / 1000),
        });
        await sleep(waitMs + 500);
        quotaDelays = [];
      }

    for (const model of MODELS) {
      for (let attempt = 1; attempt <= env.llm.maxAttempts; attempt++) {
        if (Date.now() > deadline) {
          onProgress?.({ phase: 'giving_up', reason: 'délai dépassé' });
          throw last ?? new LlmError('gemini', 'unavailable', 'deadline exceeded');
        }
        onProgress?.({ phase: 'calling', model, attempt });

        let res;
        try {
          res = await fetch(ENDPOINT + '/' + model + ':streamGenerateContent?alt=sse', {
            method: 'POST',
            headers: { 'x-goog-api-key': env.llm.googleApiKey, 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
            // Never let one slow attempt run past the whole-generation budget.
            signal: AbortSignal.timeout(Math.max(5000, Math.min(env.llm.timeoutMs, deadline - Date.now()))),
          });
        } catch (err) {
          last = new LlmError('gemini', 'network', model + ': ' + err.message);
          onProgress?.({ phase: 'retry', model, reason: 'réseau' });
          await sleep(1000 * attempt);
          continue;
        }

        if (!res.ok) {
          let detail = model + ': HTTP ' + res.status;
          let errorBody = null;
          try {
            errorBody = await res.json();
            if (errorBody?.error?.message) detail += ' ' + errorBody.error.message;
          } catch {
            /* body was not JSON */
          }

          // 400 means WE sent something malformed — that is our bug, and
          // silently falling through to another engine would hide it.
          if (res.status === 400) throw new LlmError('gemini', 'bad_request', detail);
          if (res.status === 401 || res.status === 403) throw new LlmError('gemini', 'auth', detail);

          if (res.status === 429) {
            // The free tier's 20-requests-per-minute budget is metered PER
            // MODEL (measured: 3.5-flash rate-limited while 3.6-flash and
            // 2.5-flash answered in ~1s). So rotate immediately rather than
            // sitting out this model's window - waiting is only worth it when
            // every model is exhausted, which the caller handles below.
            last = new LlmError('gemini', 'quota', detail);
            quotaDelays.push(retryDelayMs(errorBody) ?? 60000);
            onProgress?.({ phase: 'retry', model, reason: 'quota atteint, modele suivant' });
            break;
          }

          last = new LlmError('gemini', 'unavailable', detail);
          onProgress?.({ phase: 'retry', model, reason: 'modèle occupé (' + res.status + ')' });
          await sleep(1000 * attempt);
          continue;
        }

        let text;
        let finishReason;
        try {
          ({ text, finishReason } = await readStream(res, onProgress, model, env.llm.stallMs));
        } catch (err) {
          const stalled = err instanceof StallError;
          last = new LlmError(
            'gemini',
            stalled ? 'stalled' : 'network',
            model + (stalled ? ': flux interrompu — ' : ': stream broke — ') + err.message,
          );
          onProgress?.({ phase: 'retry', model, reason: stalled ? 'flux bloqué' : 'réseau' });
          await sleep(1000 * attempt);
          continue;
        }

        if (!text) {
          last = new LlmError('gemini', 'empty', model + ': no content in response');
          continue;
        }
        // A short answer still parses as valid JSON — it is simply missing
        // questions — so completeness has to be asserted, not assumed. A
        // finished Gemini response always carries finishReason 'STOP'; a
        // stream that just stops sending sets none at all, and treating that
        // absence as success is how 6 questions out of 20 got accepted.
        if (finishReason !== 'STOP') {
          last = new LlmError(
            'gemini',
            finishReason ? 'truncated' : 'incomplete',
            model + ': finishReason=' + (finishReason ?? 'aucun (flux interrompu)'),
          );
          onProgress?.({
            phase: 'retry',
            model,
            reason: finishReason ? 'réponse tronquée' : 'réponse incomplète',
          });
          continue;
        }
        try {
          return { data: JSON.parse(text), engine: 'gemini:' + model };
        } catch {
          last = new LlmError('gemini', 'bad_json', model + ': response was not valid JSON');
          continue;
        }
      }
    }
    }
    throw last ?? new LlmError('gemini', 'unavailable', 'all Gemini models failed');
  },
};
