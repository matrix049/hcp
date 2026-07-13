import { Router } from 'express';

import { requireAuth } from '../../middleware/auth.js';
import { submitResponseController } from './responses.controller.js';

const router = Router();

router.use(requireAuth);
router.post('/', submitResponseController);

export default router;
