import { env } from '../../config/env.js';
import { signAccessToken } from '../../utils/jwt.js';
import {
  extractText,
  splitIntoQuestions,
  generateSurvey,
  publishSurvey,
  listAllSurveys,
  setSurveyActive,
  listAgents,
  createAgent,
  updateAgent,
} from './admin.service.js';

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
 * POST /api/admin/surveys/generate  (multipart: file, [title])
 * Runs the pipeline and returns a preview survey JSON (NOT yet saved).
 */
export async function generateController(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded (field "file").' });
    }
    const text = await extractText(req.file);
    const questions = splitIntoQuestions(text);
    if (questions.length === 0) {
      return res.status(400).json({ error: 'No questions found in the file.' });
    }
    const survey = generateSurvey(questions, {
      title: req.body.title?.trim() || undefined,
      stamp: Date.now(),
    });
    res.json({ questionCount: questions.length, survey });
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
