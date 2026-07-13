import { query } from '../../db/pool.js';

/** List of active surveys — lightweight (no full definition). */
export async function listSurveys() {
  const { rows } = await query(
    `SELECT id, title, version, updated_at
       FROM surveys
      WHERE is_active = true
      ORDER BY title`,
  );
  return rows.map((r) => ({
    id: r.id,
    title: r.title,
    version: r.version,
    updatedAt: r.updated_at,
  }));
}

/** Full survey including its definition JSON — used for download. */
export async function getSurvey(id) {
  const { rows } = await query(
    `SELECT id, title, version, definition, updated_at
       FROM surveys
      WHERE id = $1 AND is_active = true`,
    [id],
  );
  const row = rows[0];
  if (!row) return null;
  return {
    id: row.id,
    title: row.title,
    version: row.version,
    definition: row.definition,
    updatedAt: row.updated_at,
  };
}
