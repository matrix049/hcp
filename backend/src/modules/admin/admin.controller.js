import { env } from '../../config/env.js';
import { signAccessToken } from '../../utils/jwt.js';
import {
  extractText,
  extractQuestionLines,
  generateSurveyFromText,
  publishSurvey,
  listAllSurveys,
  setSurveyActive,
  listAgents,
  createAgent,
  updateAgent,
} from './admin.service.js';
import { fixQuestionWithLlm, llmStatus } from './llm/index.js';

// ---- Auth ----
export function loginController(req, res) {
  const { email, password } = req.body || {};
  if (email !== env.admin.email || password !== env.admin.password) {
    return res.status(401).json({ error: 'Email ou mot de passe incorrect.' });
  }
  const token = signAccessToken({ role: 'admin', email });
  res.json({ token, email });
}

export function meController(req, res) {
  res.json({ email: req.admin?.email, role: 'admin' });
}

/**
 * GET /api/admin/llm/status
 * Which engines are configured — lets the panel warn before an upload.
 */
export function llmStatusController(req, res) {
  res.json(llmStatus());
}

/**
 * POST /api/admin/surveys/generate  (multipart: file, [title])
 * Runs the pipeline and returns a PREVIEW survey (NOT saved).
 *
 * `engine` and `quality` travel with the result so the review screen can tell
 * the admin which tier produced it — silent fallback is how a weak survey
 * reaches every field agent.
 */
export async function generateController(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded (field "file").' });
    }
    const text = await extractText(req.file);
    const result = await generateSurveyFromText(text, {
      title: req.body.title?.trim() || undefined,
      lines: await extractQuestionLines(req.file),
    });
    res.json({
      questionCount: result.definition.pages[0].questions.length,
      engine: result.engine,
      quality: result.quality,
      repairs: result.repairs,
      attempts: result.attempts,
      sourceText: text,
      survey: result.definition,
    });
  } catch (err) {
    if (err.status === 400) return res.status(400).json({ error: err.message });
    next(err);
  }
}

/**
 * POST /api/admin/surveys/generate-stream  (multipart: file, [title])
 *
 * Same pipeline as /generate, but reports progress over Server-Sent Events so
 * the admin sees each question appear instead of a frozen spinner. On a busy
 * free tier a document can take minutes, and silence reads as a crash.
 *
 * Events: `progress` (repeatedly), then exactly one `done` or `error`.
 */
export async function generateStreamController(req, res) {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream; charset=utf-8',
    'Cache-Control': 'no-cache, no-transform',
    Connection: 'keep-alive',
    // Proxies that buffer would defeat the whole point of streaming.
    'X-Accel-Buffering': 'no',
  });

  const send = (event, data) => {
    res.write(`event: ${event}
data: ${JSON.stringify(data)}

`);
  };

  // If the admin closes the tab mid-generation, stop writing to a dead socket.
  // Watch the RESPONSE, not the request: `req` emits 'close' as soon as multer
  // has consumed the uploaded body, which would silence progress immediately.
  let aborted = false;
  res.on('close', () => { aborted = true; });

  try {
    if (!req.file) {
      send('error', { error: 'No file uploaded (field "file").' });
      return res.end();
    }
    send('progress', { phase: 'extracting', file: req.file.originalname });

    const text = await extractText(req.file);
    send('progress', { phase: 'extracted', chars: text.length });

    const result = await generateSurveyFromText(text, {
      title: req.body.title?.trim() || undefined,
      lines: await extractQuestionLines(req.file),
      onProgress: (p) => { if (!aborted) send('progress', p); },
    });

    if (aborted) return res.end();
    send('done', {
      questionCount: result.definition.pages[0].questions.length,
      engine: result.engine,
      quality: result.quality,
      repairs: result.repairs,
      attempts: result.attempts,
      sourceText: text,
      survey: result.definition,
    });
  } catch (err) {
    // The response is already streaming, so an error is an SSE event, not a
    // status code — the client has long since received 200 OK.
    if (!aborted) send('error', { error: err.message });
  } finally {
    res.end();
  }
}

/**
 * POST /api/admin/surveys/regenerate-stream   (json)
 * Body: { sourceText, title?, instructions }
 *
 * Re-runs the whole document through the LLM with extra admin instructions
 * ("mets les revenus en tranches", "toutes les questions facultatives sauf
 * l'identification"). The file is not re-uploaded - the first generation
 * returned its extracted text, so corrections are cheap to iterate on.
 */
export async function regenerateStreamController(req, res) {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream; charset=utf-8',
    'Cache-Control': 'no-cache, no-transform',
    Connection: 'keep-alive',
    'X-Accel-Buffering': 'no',
  });
  const send = (event, data) => {
    res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
  };
  let aborted = false;
  res.on('close', () => { aborted = true; });

  try {
    const { sourceText, title, instructions } = req.body || {};
    if (!sourceText?.trim()) {
      send('error', { error: 'Texte source manquant. Relancez une génération depuis le fichier.' });
      return res.end();
    }
    if (!instructions?.trim()) {
      send('error', { error: 'Écrivez une consigne pour l’IA.' });
      return res.end();
    }

    const result = await generateSurveyFromText(sourceText, {
      title: title?.trim() || undefined,
      instructions: instructions.trim(),
      onProgress: (p) => { if (!aborted) send('progress', p); },
    });

    if (aborted) return res.end();
    send('done', {
      questionCount: result.definition.pages[0].questions.length,
      engine: result.engine,
      quality: result.quality,
      repairs: result.repairs,
      attempts: result.attempts,
      sourceText,
      survey: result.definition,
    });
  } catch (err) {
    if (!aborted) send('error', { error: err.message });
  } finally {
    res.end();
  }
}

/**
 * POST /api/admin/surveys/fix-question
 * Body: { question, instruction, sourceText? }
 * Re-generates ONE question from an admin instruction on the review screen.
 */
export async function fixQuestionController(req, res, next) {
  try {
    const { question, instruction, sourceText } = req.body || {};
    if (!question?.id || !instruction?.trim()) {
      return res.status(400).json({ error: 'question and instruction are required.' });
    }
    const result = await fixQuestionWithLlm(question, instruction.trim(), sourceText);
    if (!result.question) {
      return res.status(503).json({ error: 'Aucun moteur IA disponible.', attempts: result.attempts });
    }
    res.json({ question: result.question, engine: result.engine });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/admin/surveys/publish   (json: the survey definition)
 * Saves a (reviewed) survey so agents can download it.
 */
export async function publishController(req, res, next) {
  try {
    const definition = req.body;
    if (!definition?.id || !Array.isArray(definition?.pages)) {
      return res.status(400).json({ error: 'Invalid survey: need id and pages[].' });
    }
    const saved = await publishSurvey(definition);
    res.json({ published: true, ...saved });
  } catch (err) {
    next(err);
  }
}

// ---- Survey management ----
export async function listSurveysController(req, res, next) {
  try {
    res.json(await listAllSurveys());
  } catch (err) { next(err); }
}

export async function setSurveyActiveController(req, res, next) {
  try {
    const ok = await setSurveyActive(req.params.id, req.body.isActive);
    if (!ok) return res.status(404).json({ error: 'Survey not found.' });
    res.json({ updated: true });
  } catch (err) { next(err); }
}

// ---- Agent management ----
export async function listAgentsController(req, res, next) {
  try {
    res.json(await listAgents());
  } catch (err) { next(err); }
}

export async function createAgentController(req, res, next) {
  try {
    const a = req.body;
    if (!a.matricule || !a.firstName || !a.lastName || !a.region || !a.password) {
      return res.status(400).json({ error: 'matricule, firstName, lastName, region, password are required.' });
    }
    res.json({ created: true, ...(await createAgent(a)) });
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Ce matricule existe déjà.' });
    next(err);
  }
}

export async function updateAgentController(req, res, next) {
  try {
    const ok = await updateAgent(req.params.id, req.body);
    if (!ok) return res.status(404).json({ error: 'Agent not found.' });
    res.json({ updated: true });
  } catch (err) { next(err); }
}
