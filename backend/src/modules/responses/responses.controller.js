import { ResponseOwnershipError, upsertResponse } from './responses.service.js';

/** A response payload has to be an object of answers, not just any JSON. */
function validate({ id, surveyId, answers }) {
  const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!id || !surveyId) return 'id and surveyId are required';
  if (!uuid.test(id)) return 'id must be a UUID';
  if (typeof surveyId !== 'string' || surveyId.length > 100) return 'surveyId is invalid';
  if (answers !== undefined && (typeof answers !== 'object' || answers === null || Array.isArray(answers))) {
    return 'answers must be an object keyed by question id';
  }
  return null;
}

/** POST /api/responses  Body: { id, surveyId, answers, updatedAt } */
export async function submitResponseController(req, res, next) {
  try {
    const { id, surveyId, answers, updatedAt } = req.body ?? {};
    const problem = validate({ id, surveyId, answers });
    if (problem) return res.status(400).json({ error: problem });

    const result = await upsertResponse(req.agent.sub, {
      id,
      surveyId,
      answers,
      updatedAt,
    });
    return res.status(200).json(result);
  } catch (err) {
    if (err instanceof ResponseOwnershipError) {
      return res.status(403).json({ error: err.message });
    }
    return next(err);
  }
}
