import { verifyToken } from '../utils/jwt.js';

/**
 * Protects the admin tool: requires a valid `Authorization: Bearer <token>`
 * whose payload has `role: 'admin'`. Separate from `requireAuth` (agents), so an
 * agent token can never reach admin endpoints.
 */
export function requireAdmin(req, res, next) {
  const header = req.headers.authorization ?? '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Missing or malformed token' });
  }

  try {
    const decoded = verifyToken(token);
    if (decoded.type !== 'access' || decoded.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }
    req.admin = decoded;
    return next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
