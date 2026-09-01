import path from 'node:path';
import { fileURLToPath } from 'node:url';

import cors from 'cors';
import express from 'express';

import { env } from './config/env.js';
import { errorHandler, notFound } from './middleware/errorHandler.js';
import { loginRateLimit } from './middleware/rateLimit.js';
import adminRoutes from './modules/admin/admin.routes.js';
import authRoutes from './modules/auth/auth.routes.js';
import responseRoutes from './modules/responses/responses.routes.js';
import surveyRoutes from './modules/surveys/surveys.routes.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function createApp() {
  const app = express();

  // The Flutter web build calls this API from another origin. In production
  // CORS_ORIGINS pins the allowed origins; unset (development) keeps it open.
  const allowed = (env.corsOrigins ?? '').split(',').map((o) => o.trim()).filter(Boolean);
  app.use(cors(allowed.length > 0 ? { origin: allowed } : undefined));

  // A survey response is a small JSON map. Capping the body stops a single
  // request from allocating unbounded memory.
  app.use(express.json({ limit: '1mb' }));

  // Minimal request logging (dev observability).
  app.use((req, res, next) => {
    res.on('finish', () => {
      console.log(`${req.method} ${req.originalUrl} -> ${res.statusCode}`);
    });
    next();
  });

  app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

  // Brute-forcing a 5-character matricule is cheap without this.
  app.use('/api/auth/login', loginRateLimit);
  app.use('/api/admin/login', loginRateLimit);

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
