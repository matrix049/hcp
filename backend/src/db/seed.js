import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import bcrypt from 'bcryptjs';

import { pool } from './pool.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Seeds a test agent so the Flutter app can log in end-to-end.
 * Idempotent: re-running updates the same matricule instead of duplicating.
 *
 *   Matricule: AG001
 *   Password:  password123
 */
async function seed() {
  const passwordHash = await bcrypt.hash('password123', 10);

  await pool.query(
    `INSERT INTO agents (matricule, first_name, last_name, role, region, phone, password_hash)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     ON CONFLICT (matricule)
     DO UPDATE SET first_name = EXCLUDED.first_name,
                   last_name  = EXCLUDED.last_name,
                   role       = EXCLUDED.role,
                   region     = EXCLUDED.region,
                   phone      = EXCLUDED.phone,
                   password_hash = EXCLUDED.password_hash`,
    ['AG001', 'Youssef', 'Alaoui', 'agent', 'Rabat-Salé-Kénitra', '+212600000000', passwordHash],
  );

  console.log('✅ Seeded test agent  ->  matricule: AG001  password: password123');

  await seedSampleSurvey();
}

/** Seeds the sample survey from the shared Flutter asset (single source). */
async function seedSampleSurvey() {
  const assetPath = join(
    __dirname,
    '../../../assets/surveys/sample_household_survey.json',
  );
  const raw = await readFile(assetPath, 'utf8');
  const definition = JSON.parse(raw);

  const title =
    definition.title?.fr ?? definition.title?.en ?? definition.id;

  await pool.query(
    `INSERT INTO surveys (id, title, version, definition, is_active)
     VALUES ($1, $2, $3, $4, true)
     ON CONFLICT (id)
     DO UPDATE SET title = EXCLUDED.title,
                   version = EXCLUDED.version,
                   definition = EXCLUDED.definition,
                   is_active = true,
                   updated_at = now()`,
    [definition.id, title, definition.version ?? 1, definition],
  );

  console.log(`✅ Seeded survey  ->  ${definition.id} ("${title}")`);
}

seed()
  .catch((err) => {
    console.error('❌ Seed failed:', err.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
