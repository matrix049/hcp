import pg from 'pg';

import { env } from '../config/env.js';

/**
 * Single shared PostgreSQL connection pool for the whole app.
 * Import { query } wherever SQL is needed instead of creating new clients.
 */
export const pool = new pg.Pool({ connectionString: env.databaseUrl });

export function query(text, params) {
  return pool.query(text, params);
}
