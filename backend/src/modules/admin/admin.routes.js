import { Router } from 'express';
import multer from 'multer';

import { requireAdmin } from '../../middleware/adminAuth.js';
import {
  loginController,
  meController,
  generateController,
  publishController,
  listSurveysController,
  setSurveyActiveController,
  listAgentsController,
  createAgentController,
  updateAgentController,
} from './admin.controller.js';

// In-memory upload (files are small question lists; parsed immediately).
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
});

const router = Router();

// Public: admin login.
router.post('/login', loginController);

// Everything below requires a valid admin token.
router.use(requireAdmin);

router.get('/me', meController);

// Survey generation + management
router.post('/surveys/generate', upload.single('file'), generateController);
router.post('/surveys/publish', publishController);
router.get('/surveys', listSurveysController);
router.post('/surveys/:id/active', setSurveyActiveController);

// Agent management
router.get('/agents', listAgentsController);
router.post('/agents', createAgentController);
router.put('/agents/:id', updateAgentController);

export default router;
