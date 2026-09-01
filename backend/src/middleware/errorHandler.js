/* eslint-disable no-unused-vars */

/** 404 for unmatched routes. */
export function notFound(req, res) {
  res.status(404).json({ error: 'Not found' });
}

/**
 * Central error handler — last middleware in the chain.
 *
 * PostgreSQL constraint violations are the client's mistake, not the server's:
 * posting a response for a survey that does not exist used to surface as a
 * blanket 500 "Internal server error", which tells the caller nothing and looks
 * like a crash. They are mapped to real status codes here. The error body still
 * never carries a stack trace or SQL detail.
 */
export function errorHandler(err, req, res, next) {
  // 23503 foreign_key_violation · 23505 unique_violation · 22P02 invalid_text_representation
  const byPgCode = {
    23503: { status: 400, error: 'Référence inconnue : cette enquête ou cet agent n’existe pas.' },
    23505: { status: 409, error: 'Cet enregistrement existe déjà.' },
    '22P02': { status: 400, error: 'Format de donnée invalide.' },
  };

  const mapped = byPgCode[err?.code];
  if (mapped) {
    console.warn(`Rejected request (${err.code}): ${req.method} ${req.originalUrl}`);
    return res.status(mapped.status).json({ error: mapped.error });
  }

  if (err?.type === 'entity.too.large') {
    return res.status(413).json({ error: 'Requête trop volumineuse.' });
  }

  console.error('Unhandled error:', err);
  return res.status(500).json({ error: 'Internal server error' });
}
