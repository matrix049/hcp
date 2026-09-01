import { query } from '../../db/pool.js';

/**
 * ADMIN — getting the collected data back out.
 *
 * Responses are stored as JSONB keyed by question id, which is right for the
 * sync engine and useless for a statistician. This flattens them into one row
 * per response with one column per question, using the survey definition to
 * order the columns and to turn stored option codes back into their labels.
 */

/** RFC 4180: quote when the value contains a delimiter, quote or newline. */
function csvCell(value, delimiter) {
  const s = value === null || value === undefined ? '' : String(value);
  if (s.includes('"') || s.includes('\n') || s.includes('\r') || s.includes(delimiter)) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

/** An answer as a human reads it: option codes resolved, lists joined. */
function formatAnswer(value, question, locale) {
  if (value === null || value === undefined) return '';

  const labelFor = (code) => {
    const option = question?.options?.find((o) => o.value === code);
    if (!option) return code;
    return option.label?.[locale] ?? option.label?.fr ?? code;
  };

  // checkbox answers arrive as an array of option codes.
  if (Array.isArray(value)) return value.map(labelFor).join(' ; ');
  if (typeof value === 'boolean') return value ? 'Oui' : 'Non';
  if (question?.options) return labelFor(value);
  return String(value);
}

const isoOrEmpty = (d) => (d ? new Date(d).toISOString() : '');

/**
 * Build the export table for one survey.
 * Returns { filename, columns, rows } — the caller renders it as CSV.
 */
export async function buildSurveyExport(surveyId, { locale = 'fr' } = {}) {
  const { rows: surveyRows } = await query(
    'SELECT id, title, version, definition FROM surveys WHERE id = $1',
    [surveyId],
  );
  if (surveyRows.length === 0) return null;

  const survey = surveyRows[0];
  const questions = (survey.definition?.pages ?? []).flatMap((p) => p.questions ?? []);

  const { rows: responses } = await query(
    `SELECT r.id, r.answers, r.client_updated_at, r.synced_at,
            a.matricule, a.first_name, a.last_name, a.region
       FROM survey_responses r
       JOIN agents a ON a.id = r.agent_id
      WHERE r.survey_id = $1
      ORDER BY r.synced_at`,
    [surveyId],
  );

  const meta = ['id_reponse', 'matricule', 'enqueteur', 'region', 'rempli_le', 'synchronise_le'];
  const columns = [
    ...meta,
    ...questions.map((q) => q.label?.[locale] ?? q.label?.fr ?? q.id),
  ];

  const rows = responses.map((r) => [
    r.id,
    r.matricule,
    `${r.first_name} ${r.last_name}`.trim(),
    r.region ?? '',
    isoOrEmpty(r.client_updated_at),
    isoOrEmpty(r.synced_at),
    ...questions.map((q) => formatAnswer(r.answers?.[q.id], q, locale)),
  ]);

  return {
    filename: `${survey.id}_v${survey.version}_${new Date().toISOString().slice(0, 10)}.csv`,
    title: survey.title,
    columns,
    rows,
  };
}

/**
 * Render as CSV.
 *
 * Two deliberate choices for Excel on a French/Arabic Windows machine:
 * a UTF-8 BOM, without which Excel mangles accents and Arabic entirely; and a
 * semicolon delimiter, which is what Excel expects in locales that use the
 * comma as a decimal separator. Both are configurable for tools that want the
 * plain comma form (R, pandas, SPSS).
 */
export function toCsv({ columns, rows }, { delimiter = ';', bom = true } = {}) {
  const lines = [
    columns.map((c) => csvCell(c, delimiter)).join(delimiter),
    ...rows.map((r) => r.map((cell) => csvCell(cell, delimiter)).join(delimiter)),
  ];
  // CRLF is what RFC 4180 specifies and what Excel is happiest with.
  return (bom ? '﻿' : '') + lines.join('\r\n') + '\r\n';
}

// ===================== DASHBOARD =====================

/**
 * Everything the dashboard shows, in one round trip.
 *
 * `daily` is zero-filled across the whole window: a day with no responses is a
 * real, meaningful zero, and leaving gaps out would silently compress the time
 * axis and make an idle week look like a busy one.
 */
export async function getStats({ days = 14 } = {}) {
  const [totals, perSurvey, perAgent, perRegion, daily, latest] = await Promise.all([
    query(`SELECT
             (SELECT count(*) FROM surveys)           AS surveys,
             (SELECT count(*) FROM surveys WHERE is_active) AS active_surveys,
             (SELECT count(*) FROM agents)            AS agents,
             (SELECT count(*) FROM survey_responses)  AS responses`),
    query(
      `SELECT s.id, s.title, s.is_active, count(r.id)::int AS responses
         FROM surveys s
         LEFT JOIN survey_responses r ON r.survey_id = s.id
        GROUP BY s.id, s.title, s.is_active
        ORDER BY responses DESC, s.title`,
    ),
    query(
      `SELECT a.matricule, a.first_name, a.last_name, a.region,
              count(r.id)::int AS responses,
              max(r.synced_at) AS last_sync
         FROM agents a
         LEFT JOIN survey_responses r ON r.agent_id = a.id
        GROUP BY a.id, a.matricule, a.first_name, a.last_name, a.region
        ORDER BY responses DESC, a.matricule`,
    ),
    query(
      `SELECT a.region, count(r.id)::int AS responses
         FROM survey_responses r
         JOIN agents a ON a.id = r.agent_id
        GROUP BY a.region
        ORDER BY responses DESC`,
    ),
    query(
      `SELECT to_char(d.day, 'YYYY-MM-DD') AS day,
              count(r.id)::int AS responses
         FROM generate_series(
                (current_date - ($1::int - 1) * interval '1 day')::date,
                current_date::date,
                interval '1 day'
              ) AS d(day)
         LEFT JOIN survey_responses r
                ON r.synced_at >= d.day
               AND r.synced_at <  d.day + interval '1 day'
        GROUP BY d.day
        ORDER BY d.day`,
      [days],
    ),
    query('SELECT max(synced_at) AS last_sync FROM survey_responses'),
  ]);

  return {
    totals: {
      surveys: Number(totals.rows[0].surveys),
      activeSurveys: Number(totals.rows[0].active_surveys),
      agents: Number(totals.rows[0].agents),
      responses: Number(totals.rows[0].responses),
    },
    perSurvey: perSurvey.rows.map((r) => ({
      id: r.id,
      title: r.title,
      isActive: r.is_active,
      responses: r.responses,
    })),
    perAgent: perAgent.rows.map((r) => ({
      matricule: r.matricule,
      name: `${r.first_name} ${r.last_name}`.trim(),
      region: r.region,
      responses: r.responses,
      lastSync: r.last_sync,
    })),
    perRegion: perRegion.rows,
    daily: daily.rows,
    lastSync: latest.rows[0].last_sync,
  };
}
