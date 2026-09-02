import { Router } from 'express';
import multer from 'multer';

import { requireAdmin } from '../../middleware/adminAuth.js';
import {
  loginController,
  meController,
  generateController,
  generateStreamController,
  regenerateStreamController,
  fixQuestionController,
  llmStatusController,
  publishController,
  listSurveysController,
  exportSurveyController,
  exportPreviewController,
  statsController,
  setSurveyActiveController,
  listAgentsController,
  createAgentController,
  updateAgentController,
} from './admin.controller.js';

/**
 * Largest questionnaire the admin tool accepts, in bytes.
 *
 * Questionnaires are text: even a 200-question document sits far under this.
 * The cap exists so a mistaken upload (a scan, a video) cannot allocate
 * unbounded memory - files are held in RAM, never written to disk.
 */
export const MAX_UPLOAD_BYTES = 5 * 1024 * 1024;

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_UPLOAD_BYTES },
});

const router = Router();

// Public: admin login.
router.post('/login', loginController);

// Everything below requires a valid admin token.
router.use(requireAdmin);

router.get('/me', meController);

// Survey generation + management
router.get('/llm/status', llmStatusController);
router.post('/surveys/generate', upload.single('file'), generateController);
router.post('/surveys/generate-stream', upload.single('file'), generateStreamController);
router.post('/surveys/regenerate-stream', regenerateStreamController);
router.post('/surveys/fix-question', fixQuestionController);
router.post('/surveys/publish', publishController);
router.get('/surveys', listSurveysController);
router.post('/surveys/:id/active', setSurveyActiveController);

// Data export + dashboard
router.get('/stats', statsController);
router.get('/surveys/:id/export.csv', exportSurveyController);
router.get('/surveys/:id/export/preview', exportPreviewController);

// Agent management
router.get('/agents', listAgentsController);
router.post('/agents', createAgentController);
router.put('/agents/:id', updateAgentController);

export default router;
