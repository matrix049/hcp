import { upsertResponse } from './responses.service.js';

/** POST /api/responses  Body: { id, surveyId, answers, updatedAt } */
export async function submitResponseController(req, res, next) {
  try {
    const { id, surveyId, answers, updatedAt } = req.body ?? {};
    if (!id || !surveyId) {
      return res.status(400).json({ error: 'id and surveyId are required' });
    }
    const result = await upsertResponse(req.agent.sub, {
      id,
      surveyId,
      answers,
      updatedAt,
    });
    return res.status(200).json(result);
  } catch (err) {
    return next(err);
  }
}
