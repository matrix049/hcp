/**
 * Bout-en-bout : le parcours réel, du document Word jusqu'à l'export administrateur.
 *
 *   node eval/e2e-demo.mjs
 *
 * Rejoue exactement ce que font l'outil d'administration et l'application de
 * l'enquêteur, contre le serveur qui tourne. Chaque étape est vérifiée, et le
 * script sort en code 1 si une seule échoue — c'est une démonstration, mais
 * c'est aussi un test.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';

import 'dotenv/config';

const API = process.env.E2E_API ?? 'http://localhost:3000/api';
const here = path.dirname(fileURLToPath(import.meta.url));
const DOCS = path.resolve(here, '../../sample_docs');

const AGENT = { matricule: 'AG001', password: 'password123' };
/** Stable identity for the isolation test, so runs do not pile up agents. */
const E2E_AGENT_MATRICULE = 'AG_E2E';
const ADMIN = { email: process.env.ADMIN_EMAIL, password: process.env.ADMIN_PASSWORD };

let failures = 0;
const created = { surveyId: null, responseIds: [] };

// ─────────────────────────────────────────────────────────── affichage
const C = { g: '\x1b[32m', r: '\x1b[31m', y: '\x1b[33m', d: '\x1b[2m', b: '\x1b[1m', x: '\x1b[0m' };
const step = (n, title) => console.log(`\n${C.b}${'━'.repeat(66)}\n ÉTAPE ${n} · ${title}\n${'━'.repeat(66)}${C.x}`);
const ok = (msg) => console.log(`  ${C.g}✓${C.x} ${msg}`);
const info = (msg) => console.log(`  ${C.d}·${C.x} ${msg}`);
function check(condition, msg, detail = '') {
  if (condition) return ok(msg);
  failures += 1;
  console.log(`  ${C.r}✗ ${msg}${C.x}${detail ? `\n      ${C.d}${detail}${C.x}` : ''}`);
}

async function api(pathname, { token, method = 'GET', body, form } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body) headers['Content-Type'] = 'application/json';
  const res = await fetch(API + pathname, {
    method,
    headers,
    body: form ?? (body ? JSON.stringify(body) : undefined),
  });
  // Read the bytes, not the decoded string: the WHATWG UTF-8 decoder strips a
  // leading BOM, so `res.text()` cannot be used to prove the CSV carries one.
  const bytes = new Uint8Array(await res.arrayBuffer());
  const text = new TextDecoder('utf-8').decode(bytes);
  let json = null;
  try { json = JSON.parse(text); } catch { /* CSV or plain text */ }
  return { status: res.status, json, text, bytes, headers: res.headers };
}

// ═══════════════════════════════════════════════════════════════════════
console.log(`${C.b}\nDÉMONSTRATION COMPLÈTE — Application d'enquêtes HCP${C.x}`);
console.log(`${C.d}${new Date().toLocaleString('fr-FR')} · ${API}${C.x}`);

// ─────────────────────────────────────────── 0
step(0, 'Le serveur répond');
const health = await api('/health');
check(health.json?.status === 'ok', 'API disponible', `reçu : ${health.status}`);
if (health.json?.status !== 'ok') {
  console.log(`\n${C.r}Le backend ne répond pas. Lancez-le avec : cd backend && npm start${C.x}\n`);
  process.exit(1);
}

// ─────────────────────────────────────────── ménage d'avant-course
step(0.5, "Effacement des exécutions précédentes");
const { pool } = await import('../src/db/pool.js');
const gone = await pool.query(
  `WITH doomed AS (DELETE FROM survey_responses
                    WHERE survey_id LIKE 'survey_demo_%' RETURNING 1)
   SELECT (SELECT count(*) FROM doomed) AS responses`,
);
const droppedSurveys = await pool.query(
  `DELETE FROM surveys WHERE id LIKE 'survey_demo_%' RETURNING 1`,
);
info(`${droppedSurveys.rowCount} enquête(s) et ${gone.rows[0].responses} réponse(s) de démonstration effacées`);
ok('la base ne garde aucun déchet des exécutions passées');

// ─────────────────────────────────────────── 1
step(1, "L'administrateur se connecte");
const adminLogin = await api('/admin/login', { method: 'POST', body: ADMIN });
check(adminLogin.status === 200, `connexion admin (${ADMIN.email})`, adminLogin.text.slice(0, 120));
const adminToken = adminLogin.json?.token;

const wrongAdmin = await api('/admin/login', { method: 'POST', body: { ...ADMIN, password: 'faux' } });
check(wrongAdmin.status === 401, 'un mauvais mot de passe est refusé (401)');

// ─────────────────────────────────────────── 2
step(2, 'Conversion du document Word en questionnaire');
const docPath = path.join(DOCS, '01_demo_rapide_10_questions.docx');
const form = new FormData();
form.append('file', new Blob([fs.readFileSync(docPath)]), path.basename(docPath));
form.append('title', 'Démonstration encadrant');

info(`document : ${path.basename(docPath)}`);
const t0 = Date.now();
const gen = await api('/admin/surveys/generate', { token: adminToken, method: 'POST', form });
const genSeconds = ((Date.now() - t0) / 1000).toFixed(1);

check(gen.status === 200, `génération terminée en ${genSeconds}s`, gen.text.slice(0, 160));
const survey = gen.json?.survey;
const engine = gen.json?.engine ?? '—';
info(`moteur utilisé : ${engine}${gen.json?.quality === 'ai' ? '' : `  ${C.y}(repli sans IA)${C.x}`}`);
check(gen.json?.questionCount === 10, `10 questions extraites (reçu : ${gen.json?.questionCount})`);

const questions = survey?.pages?.[0]?.questions ?? [];
const types = [...new Set(questions.map((q) => q.type))];
info(`types produits : ${types.join(', ')}`);
check(questions.every((q) => ['text', 'number', 'radio', 'checkbox', 'dropdown', 'date'].includes(q.type)),
  "tous les types sont rendus par l'application");
check(questions.some((q) => q.options?.length >= 2), 'des questions à choix ont bien des options');
check(questions.some((q) => !q.required), '« (facultatif) » est respecté');
check(questions.every((q) => q.label?.ar?.trim()), 'chaque question est traduite en arabe');
check(survey?.locales?.includes('ar'), "l'enquête déclare la locale arabe");

// ─────────────────────────────────────────── 3
step(3, "Publication : l'enquête devient visible pour les enquêteurs");
const surveyId = `survey_demo_${Date.now()}`;
const toPublish = { ...survey, id: surveyId };
const pub = await api('/admin/surveys/publish', { token: adminToken, method: 'POST', body: toPublish });
check(pub.status === 200 && pub.json?.published, 'enquête publiée', pub.text.slice(0, 120));
created.surveyId = surveyId;
info(`identifiant : ${surveyId}`);

// ─────────────────────────────────────────── 4
step(4, "L'enquêteur se connecte et télécharge l'enquête");
const login = await api('/auth/login', { method: 'POST', body: AGENT });
check(login.status === 200, `connexion enquêteur (${AGENT.matricule})`, login.text.slice(0, 120));
const agentToken = login.json?.accessToken;
const agentName = `${login.json?.user?.firstName ?? ''} ${login.json?.user?.lastName ?? ''}`.trim();
info(`enquêteur : ${agentName} · ${login.json?.user?.region ?? ''}`);

const list = await api('/surveys', { token: agentToken });
check(list.json?.some?.((s) => s.id === surveyId), "la nouvelle enquête apparaît dans sa liste");

const download = await api(`/surveys/${surveyId}`, { token: agentToken });
check(download.status === 200, "téléchargement du questionnaire complet");
check(download.json?.definition?.pages?.[0]?.questions?.length === 10,
  'les 10 questions sont dans le fichier téléchargé');
info('à partir d’ici, le questionnaire est en base locale : plus besoin de réseau');

// ─────────────────────────────────────────── 5
step(5, 'ZONE RURALE — remplissage hors ligne, rien n’est envoyé');
console.log(`  ${C.d}L'application n'appelle jamais le réseau depuis un écran : elle écrit dans`);
console.log(`  SQLite. On simule ici trois réponses créées sans aucun appel au serveur.${C.x}\n`);

const drafts = [
  { region: 'rabat_sale_kenitra', personnes: 4, revenu: 6500 },
  { region: 'marrakech_safi', personnes: 7, revenu: 3200 },
  { region: 'casablanca_settat', personnes: 2, revenu: 9800 },
];

const localQueue = drafts.map((d) => ({
  id: randomUUID(),                       // UUID généré sur le téléphone
  surveyId,
  status: 'draft',
  answers: {
    [questions[0]?.id ?? 'q_1']: 'Ménage enquêté hors ligne',
    [questions[3]?.id ?? 'q_4']: d.personnes,
  },
  updatedAt: new Date().toISOString(),
}));

localQueue.forEach((r, i) =>
  info(`brouillon ${i + 1} enregistré localement · id ${r.id.slice(0, 8)}… · statut « draft »`));

const before = await api(`/admin/surveys/${surveyId}/export/preview`, { token: adminToken });
check(before.json?.totalRows === 0,
  `le serveur ne connaît encore AUCUNE réponse (reçu : ${before.json?.totalRows})`);
ok('le travail hors ligne est bien invisible du serveur — comme attendu');

localQueue.forEach((r) => { r.status = 'pending'; });
info('l’enquêteur valide ses 3 réponses : statut « draft » → « pending »');

// ─────────────────────────────────────────── 6
step(6, 'RETOUR DU RÉSEAU — synchronisation');
console.log(`  ${C.d}C'est exactement ce que fait SyncEngine.syncPending().${C.x}\n`);

for (const [i, r] of localQueue.entries()) {
  const up = await api('/responses', {
    token: agentToken,
    method: 'POST',
    body: { id: r.id, surveyId: r.surveyId, answers: r.answers, updatedAt: r.updatedAt },
  });
  check(up.status === 200 && up.json?.status === 'synced',
    `réponse ${i + 1}/3 envoyée · ${r.id.slice(0, 8)}…`, up.text.slice(0, 120));
  if (up.status === 200) { r.status = 'synced'; created.responseIds.push(r.id); }
}

// ─────────────────────────────────────────── 7
step(7, 'Robustesse : le réseau coupe en plein envoi, on réessaie');
const retry = localQueue[0];
const again = await api('/responses', {
  token: agentToken,
  method: 'POST',
  body: { id: retry.id, surveyId: retry.surveyId, answers: retry.answers, updatedAt: retry.updatedAt },
});
check(again.status === 200, 'le même envoi rejoué est accepté');

const afterRetry = await api(`/admin/surveys/${surveyId}/export/preview`, { token: adminToken });
check(afterRetry.json?.totalRows === 3,
  `toujours 3 réponses, aucun doublon (reçu : ${afterRetry.json?.totalRows})`);
ok("l'UUID généré par le téléphone rend l'envoi idempotent");

// ─────────────────────────────────────────── 8
step(8, "Un autre enquêteur ne peut pas écraser ces réponses");
const other = await api('/admin/agents', {
  token: adminToken, method: 'POST',
  body: { matricule: E2E_AGENT_MATRICULE, firstName: 'Test', lastName: 'Cloisonnement',
          region: 'Fès-Meknès', password: 'password123', role: 'agent' },
});
if (other.status === 409) info(`enquêteur de test ${E2E_AGENT_MATRICULE} déjà présent, réutilisé`);
// Reused across runs on purpose: there is no delete-agent endpoint, so a
// random matricule each time would slowly fill the agents table with clones.
const agents = await api('/admin/agents', { token: adminToken });
const intruder = agents.json?.find((a) => a.matricule === E2E_AGENT_MATRICULE);
check(other.status === 200 || intruder, 'second enquêteur disponible pour le test de cloisonnement');
if (intruder) {
  const li = await api('/auth/login', { method: 'POST', body: { matricule: intruder.matricule, password: 'password123' } });
  const steal = await api('/responses', {
    token: li.json?.accessToken, method: 'POST',
    body: { id: retry.id, surveyId, answers: { pirate: true }, updatedAt: new Date().toISOString() },
  });
  check(steal.status === 403, 'tentative d’écrasement refusée (403)', `reçu : ${steal.status}`);
} else {
  info('second enquêteur non créé — test d’écrasement ignoré');
}

// ─────────────────────────────────────────── 9
step(9, "L'ADMINISTRATEUR voit les réponses de l'enquêteur");
const stats = await api('/admin/stats', { token: adminToken });
const thisSurvey = stats.json?.perSurvey?.find((x) => x.id === surveyId);
check(thisSurvey?.responses === 3, `le tableau de bord compte 3 réponses (reçu : ${thisSurvey?.responses})`);

const agentRow = stats.json?.perAgent?.find((a) => a.matricule === AGENT.matricule);
check((agentRow?.responses ?? 0) >= 3, `${agentRow?.name} apparaît avec ${agentRow?.responses} réponse(s)`);
info(`dernière synchronisation : ${new Date(stats.json?.lastSync).toLocaleString('fr-FR')}`);

const csv = await api(`/admin/surveys/${surveyId}/export.csv`, { token: adminToken });
check(csv.status === 200, 'export CSV téléchargeable');
const hasBom = csv.bytes?.[0] === 0xef && csv.bytes?.[1] === 0xbb && csv.bytes?.[2] === 0xbf;
check(hasBom, 'BOM UTF-8 présent (Excel lit les accents et l’arabe)',
  `premiers octets : ${[...(csv.bytes ?? []).slice(0, 3)].map((b) => b.toString(16)).join(' ')}`);
const lines = csv.text.replace(/^﻿/, '').trim().split('\r\n');
check(lines.length === 4, `1 en-tête + 3 réponses (reçu : ${lines.length} lignes)`);
check(lines[0].includes('matricule') && lines[0].includes('enqueteur'),
  "chaque ligne est tracée jusqu'à l'enquêteur");
check(lines.slice(1).every((l) => l.includes(AGENT.matricule)),
  `les 3 lignes portent bien le matricule ${AGENT.matricule}`);

console.log(`\n  ${C.d}Extrait du fichier remis au statisticien :${C.x}`);
console.log(`  ${C.d}${lines[0].slice(0, 100)}…${C.x}`);
console.log(`  ${C.d}${lines[1].slice(0, 100)}…${C.x}`);

const csvAr = await api(`/admin/surveys/${surveyId}/export.csv?locale=ar`, { token: adminToken });
check(/[؀-ۿ]/.test(csvAr.text), "l'export existe aussi en arabe");

// ─────────────────────────────────────────── nettoyage
step(10, 'Nettoyage');
await api(`/admin/surveys/${surveyId}/active`, { token: adminToken, method: 'POST', body: { isActive: false } });
ok(`enquête « ${surveyId} » masquée — elle n'apparaît plus aux enquêteurs`);
info('elle sera effacée, avec ses réponses, au prochain lancement de ce script');
await pool.end();

// ─────────────────────────────────────────── bilan
console.log(`\n${C.b}${'═'.repeat(66)}${C.x}`);
if (failures === 0) {
  console.log(`${C.g}${C.b} TOUT EST VERT — la chaîne complète fonctionne${C.x}`);
  console.log(`${C.d} Word → IA → publication → téléchargement → hors ligne → synchro`);
  console.log(` → anti-doublon → cloisonnement entre enquêteurs → tableau de bord → export${C.x}`);
} else {
  console.log(`${C.r}${C.b} ${failures} VÉRIFICATION(S) EN ÉCHEC${C.x}`);
}
console.log(`${C.b}${'═'.repeat(66)}${C.x}\n`);
process.exit(failures === 0 ? 0 : 1);
