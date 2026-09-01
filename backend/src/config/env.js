import dotenv from 'dotenv';

dotenv.config();

/**
 * Centralised, validated environment configuration.
 * Fail fast at startup if a required variable is missing.
 */
function required(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const env = {
  port: Number(process.env.PORT ?? 3000),
  databaseUrl: required('DATABASE_URL'),
  jwt: {
    secret: required('JWT_SECRET'),
    accessExpires: process.env.JWT_ACCESS_EXPIRES ?? '1h',
    refreshExpires: process.env.JWT_REFRESH_EXPIRES ?? '30d',
  },
  admin: {
    email: process.env.ADMIN_EMAIL ?? 'hcp@admin.com',
    password: process.env.ADMIN_PASSWORD ?? 'password123',
  },
  llm: {
    // Both optional: with neither key the generator falls back to the regex
    // heuristic, so the admin tool degrades instead of failing.
    anthropicApiKey: process.env.ANTHROPIC_API_KEY ?? '',
    googleApiKey: process.env.GOOGLE_API_KEY ?? '',
    enabled: process.env.LLM_ENABLED !== 'false',
    timeoutMs: Number(process.env.LLM_TIMEOUT_MS ?? 120000),
    maxAttempts: Number(process.env.LLM_MAX_ATTEMPTS ?? 2),
    // Longest we will sit waiting out a free-tier rate-limit window before
    // giving up on the provider (its budget resets every minute).
    maxQuotaWaitMs: Number(process.env.LLM_MAX_QUOTA_WAIT_MS ?? 70000),
    // Whole-generation budget. Without it a bad free-tier day burns minutes
    // across every model and still ends on the heuristic - the admin would
    // rather have the weaker answer quickly than the same answer late.
    deadlineMs: Number(process.env.LLM_DEADLINE_MS ?? 150000),
    // A busy free tier accepts the request, sends a few questions, then goes
    // silent. Abandon an attempt after this long with no data and try the next
    // model, rather than holding a dead connection until the request timeout.
    stallMs: Number(process.env.LLM_STALL_MS ?? 25000),
  },
};
