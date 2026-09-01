import { query } from '../../db/pool.js';

/** Raised when a response id already belongs to a different agent. */
export class ResponseOwnershipError extends Error {
  constructor() {
    super('This response belongs to another agent');
    this.name = 'ResponseOwnershipError';
  }
}

/**
 * Idempotent upsert of a submitted response, keyed by the client's UUID.
 * The agent id comes from the authenticated token, never the client body.
 *
 * The `WHERE` on the conflict branch is the ownership check: without it, any
 * agent who knows (or guesses) another agent's response UUID could overwrite
 * its answers, and because `agent_id` is not in the SET the row would stay
 * attributed to the original agent. With it, a foreign id updates nothing and
 * RETURNING yields no row, which the caller turns into a 403.
 */
export async function upsertResponse(agentId, { id, surveyId, answers, updatedAt }) {
  const { rows } = await query(
    `INSERT INTO survey_responses (id, survey_id, agent_id, answers, client_updated_at)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (id) DO UPDATE
       SET answers = EXCLUDED.answers,
           client_updated_at = EXCLUDED.client_updated_at,
           synced_at = now()
     WHERE survey_responses.agent_id = EXCLUDED.agent_id
     RETURNING id`,
    [id, surveyId, agentId, answers ?? {}, updatedAt ?? null],
  );
  if (rows.length === 0) throw new ResponseOwnershipError();
  return { id: rows[0].id, status: 'synced' };
}
