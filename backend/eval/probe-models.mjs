/**
 * Rank every text-capable Gemini model by whether it can actually answer our
 * real request right now (same schema, same system prompt), and how fast.
 * The popular models are the contended ones; the quota is per model, so a
 * less fashionable model is often the reliable one.
 */
import 'dotenv/config';

const KEY = process.env.GOOGLE_API_KEY;
const { SURVEY_SCHEMA } = await import('../src/modules/admin/llm/schema.js');
const { SYSTEM_PROMPT, buildGenerateUserPrompt } = await import('../src/modules/admin/llm/prompt.js');

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

const DOC = [
  '1. Nom et prenom du chef de menage',
  '2. Date de la visite',
  '3. Milieu de residence (Urbain / Rural)',
  '4. Combien de personnes vivent dans le menage ?',
  '5. Situation matrimoniale du chef de menage',
  '6. Observations (facultatif)',
].join('\n');

const body = {
  systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
  contents: [{ role: 'user', parts: [{ text: buildGenerateUserPrompt(DOC) }] }],
  generationConfig: {
    responseMimeType: 'application/json',
    responseSchema: toGeminiSchema(SURVEY_SCHEMA),
    temperature: 0,
    maxOutputTokens: 32768,
  },
};

// Everything that plausibly does text generation; image/audio/video/embedding
// models are excluded by name.
const list = await (
  await fetch('https://generativelanguage.googleapis.com/v1beta/models?pageSize=200', {
    headers: { 'x-goog-api-key': KEY },
  })
).json();

const candidates = list.models
  .filter((m) => (m.supportedGenerationMethods ?? []).includes('generateContent'))
  .map((m) => m.name.replace('models/', ''))
  .filter((n) => !/image|audio|tts|video|veo|lyria|embedding|robotics|computer-use|transcribe|live|deep-research|aqa|omni/i.test(n));

console.log('Modeles testes : ' + candidates.length + '\n');
console.log('modele'.padEnd(34) + 'statut'.padEnd(14) + 'temps'.padEnd(9) + 'questions');
console.log('-'.repeat(74));

const results = [];
for (const model of candidates) {
  const t0 = Date.now();
  let status = '';
  let count = '';
  try {
    const res = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/models/' + model + ':generateContent',
      {
        method: 'POST',
        headers: { 'x-goog-api-key': KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(70000),
      },
    );
    const json = await res.json();
    if (!res.ok) {
      status = res.status === 429 ? 'QUOTA (429)' : 'HTTP ' + res.status;
    } else {
      const c = json.candidates?.[0];
      const text = c?.content?.parts?.[0]?.text;
      if (c?.finishReason !== 'STOP') status = 'INCOMPLET';
      else if (!text) status = 'VIDE';
      else {
        try {
          count = String(JSON.parse(text).questions?.length ?? '?');
          status = 'OK';
        } catch {
          status = 'JSON INVALIDE';
        }
      }
    }
  } catch (e) {
    status = e.name === 'TimeoutError' ? 'TIMEOUT' : 'ERREUR';
  }
  const ms = Date.now() - t0;
  results.push({ model, status, ms, count });
  console.log(model.padEnd(34) + status.padEnd(14) + ((ms / 1000).toFixed(1) + 's').padEnd(9) + count);
}

console.log('\n=== CLASSEMENT (OK, du plus rapide au plus lent) ===');
results
  .filter((r) => r.status === 'OK')
  .sort((a, b) => a.ms - b.ms)
  .forEach((r, i) => console.log(String(i + 1).padStart(2) + '. ' + r.model.padEnd(32) + (r.ms / 1000).toFixed(1) + 's  (' + r.count + ' questions)'));
