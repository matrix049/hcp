-- HCP Survey — database schema.
-- Run via: npm run db:migrate

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid()

-- The "agents" table maps 1:1 to the Flutter AgentUser entity.
-- The respondent (citizen) is NOT stored here — that belongs to survey responses.
CREATE TABLE IF NOT EXISTS agents (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    matricule     VARCHAR(50)  UNIQUE NOT NULL,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    role          VARCHAR(50)  NOT NULL DEFAULT 'agent',
    region        VARCHAR(100) NOT NULL,
    phone         VARCHAR(30),
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Survey definitions. The questionnaire is NOT modelled as columns — the whole
-- survey JSON lives untouched in `definition` (JSONB), so any survey shape is
-- supported without schema changes. Mirrors the Flutter Drift `surveys` table.
CREATE TABLE IF NOT EXISTS surveys (
    id         VARCHAR(100) PRIMARY KEY,      -- the survey JSON's own id
    title      VARCHAR(255) NOT NULL,          -- display title (French)
    version    INTEGER      NOT NULL DEFAULT 1,
    definition JSONB        NOT NULL,
    is_active  BOOLEAN      NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Submitted survey responses. The primary key is the CLIENT-generated UUID, so
-- re-uploading the same response is idempotent (ON CONFLICT DO UPDATE) — the
-- sync engine can safely retry without creating duplicates.
CREATE TABLE IF NOT EXISTS survey_responses (
    id                UUID PRIMARY KEY,
    survey_id         VARCHAR(100) NOT NULL REFERENCES surveys(id),
    agent_id          UUID NOT NULL REFERENCES agents(id),
    answers           JSONB NOT NULL DEFAULT '{}'::jsonb,
    client_updated_at TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    synced_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
