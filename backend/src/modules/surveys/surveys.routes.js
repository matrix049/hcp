import { Router } from 'express';

import { requireAuth } from '../../middleware/auth.js';
import {
  getSurveyController,
  listSurveysController,
} from './surveys.controller.js';

const router = Router();

// All survey endpoints require a valid JWT.
router.use(requireAuth);

router.get('/', listSurveysController);
router.get('/:id', getSurveyController);

export default router;
