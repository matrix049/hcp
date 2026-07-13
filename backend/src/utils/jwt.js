import jwt from 'jsonwebtoken';

import { env } from '../config/env.js';

export function signAccessToken(payload) {
  return jwt.sign({ ...payload, type: 'access' }, env.jwt.secret, {
    expiresIn: env.jwt.accessExpires,
  });
}

export function signRefreshToken(payload) {
  return jwt.sign({ ...payload, type: 'refresh' }, env.jwt.secret, {
    expiresIn: env.jwt.refreshExpires,
  });
}

export function verifyToken(token) {
  return jwt.verify(token, env.jwt.secret);
}
