import { getSurvey, listSurveys } from './surveys.service.js';

/** GET /api/surveys */
export async function listSurveysController(req, res, next) {
  try {
    res.json(await listSurveys());
  } catch (err) {
    next(err);
  }
}

/** GET /api/surveys/:id */
export async function getSurveyController(req, res, next) {
  try {
    const survey = await getSurvey(req.params.id);
    if (!survey) return res.status(404).json({ error: 'Survey not found' });
    res.json(survey);
  } catch (err) {
    next(err);
  }
}
