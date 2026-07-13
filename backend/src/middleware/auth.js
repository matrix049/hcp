import { verifyToken } from '../utils/jwt.js';

/**
 * Protects routes: requires a valid `Authorization: Bearer <token>` header.
 * Attaches the decoded claims to `req.agent`.
 */
export function requireAuth(req, res, next) {
  const header = req.headers.authorization ?? '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Missing or malformed token' });
  }

  try {
    const decoded = verifyToken(token);
    // A refresh token must never be accepted on a protected route.
    if (decoded.type !== 'access') {
      return res.status(401).json({ error: 'Invalid token type' });
    }
    req.agent = decoded;
    return next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
