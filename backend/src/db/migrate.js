import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { pool } from './pool.js';

/**
 * Minimal migration runner: applies schema.sql.
 * (A full migration tool is unnecessary at this stage — we keep it simple.)
 */
const __dirname = dirname(fileURLToPath(import.meta.url));

async function migrate() {
  const sql = await readFile(join(__dirname, 'schema.sql'), 'utf8');
  await pool.query(sql);
  console.log('✅ Migration applied (schema.sql).');
}

migrate()
  .catch((err) => {
    console.error('❌ Migration failed:', err.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
