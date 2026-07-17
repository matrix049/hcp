import path from 'node:path';
import { fileURLToPath } from 'node:url';

import cors from 'cors';
import express from 'express';

import { errorHandler, notFound } from './middleware/errorHandler.js';
import adminRoutes from './modules/admin/admin.routes.js';
import authRoutes from './modules/auth/auth.routes.js';
import responseRoutes from './modules/responses/responses.routes.js';
import surveyRoutes from './modules/surveys/surveys.routes.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function createApp() {
  const app = express();

  app.use(cors()); // needed for the Flutter web target
  app.use(express.json());

  // Minimal request logging (dev observability).
  app.use((req, res, next) => {
    res.on('finish', () => {
      console.log(`${req.method} ${req.originalUrl} -> ${res.statusCode}`);
    });
    next();
  });

  app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

  app.use('/api/auth', authRoutes);
  app.use('/api/surveys', surveyRoutes);
  app.use('/api/responses', responseRoutes);
  app.use('/api/admin', adminRoutes);

  // Admin web tool (survey generator) — served at /admin
  app.use('/admin', express.static(path.join(__dirname, '../public/admin')));

  app.use(notFound);
  app.use(errorHandler);

  return app;
}
