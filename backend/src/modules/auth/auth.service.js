import bcrypt from 'bcryptjs';

import { query } from '../../db/pool.js';
import {
  signAccessToken,
  signRefreshToken,
  verifyToken,
} from '../../utils/jwt.js';

/** Thrown for a failed login; the controller maps it to HTTP 401. */
export class InvalidCredentialsError extends Error {
  constructor() {
    super('Invalid matricule or password');
    this.name = 'InvalidCredentialsError';
  }
}

/** Thrown when a refresh token is missing, malformed, or expired. */
export class InvalidRefreshTokenError extends Error {
  constructor() {
    super('Invalid or expired refresh token');
    this.name = 'InvalidRefreshTokenError';
  }
}

/** Maps a DB row (snake_case) to the Flutter AgentUser JSON (camelCase). */
function toAgentUser(row) {
  return {
    id: row.id,
    matricule: row.matricule,
    firstName: row.first_name,
    lastName: row.last_name,
    role: row.role,
    region: row.region,
    phone: row.phone ?? null,
  };
}

/**
 * Authenticates an agent by matricule + password.
 * Returns { accessToken, refreshToken, user } on success.
 */
export async function login({ matricule, password }) {
  const { rows } = await query(
    'SELECT * FROM agents WHERE matricule = $1',
    [matricule],
  );
  const agent = rows[0];
  if (!agent) throw new InvalidCredentialsError();

  const ok = await bcrypt.compare(password, agent.password_hash);
  if (!ok) throw new InvalidCredentialsError();

  const claims = { sub: agent.id, matricule: agent.matricule };
  return {
    accessToken: signAccessToken(claims),
    refreshToken: signRefreshToken(claims),
    user: toAgentUser(agent),
  };
}

/**
 * Exchanges a valid refresh token for a fresh access + refresh token pair
 * (token rotation). Rejects anything that isn't a live refresh token whose
 * agent still exists.
 */
export async function refreshTokens(refreshToken) {
  let decoded;
  try {
    decoded = verifyToken(refreshToken);
  } catch {
    throw new InvalidRefreshTokenError();
  }
  if (decoded.type !== 'refresh') throw new InvalidRefreshTokenError();

  const { rows } = await query(
    'SELECT id, matricule FROM agents WHERE id = $1',
    [decoded.sub],
  );
  const agent = rows[0];
  if (!agent) throw new InvalidRefreshTokenError();

  const claims = { sub: agent.id, matricule: agent.matricule };
  return {
    accessToken: signAccessToken(claims),
    refreshToken: signRefreshToken(claims),
  };
}
