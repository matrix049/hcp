import { query } from '../../db/pool.js';

/**
 * Idempotent upsert of a submitted response, keyed by the client's UUID.
 * The agent id comes from the authenticated token, never the client body.
 */
export async function upsertResponse(agentId, { id, surveyId, answers, updatedAt }) {
  const { rows } = await query(
    `INSERT INTO survey_responses (id, survey_id, agent_id, answers, client_updated_at)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (id) DO UPDATE
       SET answers = EXCLUDED.answers,
           client_updated_at = EXCLUDED.client_updated_at,
           synced_at = now()
     RETURNING id`,
    [id, surveyId, agentId, answers ?? {}, updatedAt ?? null],
  );
  return { id: rows[0].id, status: 'synced' };
}
