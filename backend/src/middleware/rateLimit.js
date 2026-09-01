import { env } from '../config/env.js';

/**
 * A small fixed-window rate limiter for the login endpoints.
 *
 * Deliberately dependency-free and in-memory: this API runs as a single
 * process, and pulling in a package to count integers would be more moving
 * parts than the problem deserves. If the backend is ever scaled to several
 * instances this must move to Redis — each process currently keeps its own
 * count, so N instances allow N times the attempts.
 */
const hits = new Map();

function clientKey(req) {
  // Behind a proxy, express only trusts X-Forwarded-For when 'trust proxy' is
  // set; req.ip falls back to the socket address, which is what we want here.
  return req.ip ?? req.socket?.remoteAddress ?? 'unknown';
}

export function loginRateLimit(req, res, next) {
  const { windowMs, maxAttempts } = env.rateLimit;
  const now = Date.now();
  const key = clientKey(req);

  const entry = hits.get(key);
  if (!entry || now > entry.resetAt) {
    hits.set(key, { count: 1, resetAt: now + windowMs });
    return next();
  }

  entry.count += 1;
  if (entry.count > maxAttempts) {
    const retryAfter = Math.ceil((entry.resetAt - now) / 1000);
    res.setHeader('Retry-After', String(retryAfter));
    return res.status(429).json({
      error: `Trop de tentatives de connexion. Réessayez dans ${retryAfter} seconde(s).`,
    });
  }
  return next();
}

// Keep the map from growing without bound on a long-running process.
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of hits) if (now > entry.resetAt) hits.delete(key);
}, 60_000).unref();
