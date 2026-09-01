import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { normalizeSurvey, slug, toSurveyDefinition } from '../src/modules/admin/llm/schema.js';

/**
 * `normalizeSurvey` is the last line of defence between a language model and
 * the agents' phones. Every case below is a mistake a model actually made
 * during development, so these tests are a record of real failures, not
 * hypothetical ones.
 */
describe('normalizeSurvey', () => {
  const ok = (extra = {}) => ({
    title: { fr: 'Enquête', ar: 'بحث' },
    questions: [{ id: 'q_1', type: 'text', label: { fr: 'Nom', ar: 'الاسم' }, required: true, ...extra }],
  });

  it('keeps a well-formed question untouched', () => {
    const { survey, repairs } = normalizeSurvey(ok());
    assert.equal(survey.questions.length, 1);
    assert.equal(repairs.length, 0);
  });

  it('downgrades a type the app cannot render, and says so', () => {
    const { survey, repairs } = normalizeSurvey(ok({ type: 'signature' }));
    assert.equal(survey.questions[0].type, 'text');
    assert.equal(repairs.length, 1);
  });

  it('downgrades a choice question that arrived without options', () => {
    const { survey, repairs } = normalizeSurvey(ok({ type: 'radio' }));
    assert.equal(survey.questions[0].type, 'text');
    assert.match(repairs[0], /sans options/);
  });

  it('strips options from a type that cannot use them', () => {
    const { survey } = normalizeSurvey(
      ok({ type: 'number', options: [{ value: 'a', label: { fr: 'A' } }, { value: 'b', label: { fr: 'B' } }] }),
    );
    assert.equal(survey.questions[0].options, undefined);
  });

  it('drops the stray validation Gemini attaches to text questions', () => {
    const { survey } = normalizeSurvey(ok({ validation: { min: 0 } }));
    assert.equal(survey.questions[0].validation, undefined);
  });

  it('keeps validation on numbers and swaps an inverted range', () => {
    const { survey, repairs } = normalizeSurvey(
      ok({ type: 'number', validation: { min: 120, max: 0 } }),
    );
    assert.deepEqual(survey.questions[0].validation, { min: 0, max: 120 });
    assert.match(repairs[0], /min > max/);
  });

  it('de-duplicates option values so answers stay unambiguous', () => {
    const { survey } = normalizeSurvey(
      ok({
        type: 'radio',
        options: [
          { value: 'oui', label: { fr: 'Oui' } },
          { value: 'oui', label: { fr: 'Oui (bis)' } },
        ],
      }),
    );
    const values = survey.questions[0].options.map((o) => o.value);
    assert.equal(new Set(values).size, values.length);
  });

  it('renumbers ids contiguously after dropping an empty question', () => {
    const { survey } = normalizeSurvey({
      title: { fr: 'T', ar: 'ت' },
      questions: [
        { id: 'q_1', type: 'text', label: {}, required: true },
        { id: 'q_2', type: 'text', label: { fr: 'Vrai', ar: 'ح' }, required: true },
      ],
    });
    assert.deepEqual(survey.questions.map((q) => q.id), ['q_1']);
  });

  it('defaults required to true when the model omits it', () => {
    const { survey } = normalizeSurvey({
      title: { fr: 'T' },
      questions: [{ id: 'q_1', type: 'text', label: { fr: 'X' } }],
    });
    assert.equal(survey.questions[0].required, true);
  });

  it('survives junk input instead of throwing', () => {
    const { survey } = normalizeSurvey(null);
    assert.deepEqual(survey.questions, []);
  });
});

describe('slug', () => {
  it('strips accents and spaces', () => {
    assert.equal(slug('Rabat-Salé-Kénitra'), 'rabat_sale_kenitra');
  });
  it('never returns an empty value', () => {
    assert.equal(slug('???'), 'opt');
  });
});

describe('toSurveyDefinition', () => {
  it('declares Arabic only when the survey actually carries it', () => {
    const bilingual = toSurveyDefinition({
      title: { fr: 'T', ar: 'ت' },
      questions: [{ id: 'q_1', type: 'text', label: { fr: 'A', ar: 'ب' }, required: true }],
    });
    assert.deepEqual(bilingual.locales, ['fr', 'ar']);

    const frenchOnly = toSurveyDefinition({
      title: { fr: 'T', ar: '' },
      questions: [{ id: 'q_1', type: 'text', label: { fr: 'A', ar: '' }, required: true }],
    });
    assert.deepEqual(frenchOnly.locales, ['fr']);
  });

  it('wraps questions in the single page shape the app parses', () => {
    const def = toSurveyDefinition(
      { title: { fr: 'T', ar: '' }, questions: [] },
      { id: 'survey_x', version: 3 },
    );
    assert.equal(def.id, 'survey_x');
    assert.equal(def.version, 3);
    assert.equal(def.pages.length, 1);
    assert.equal(def.pages[0].id, 'page_1');
  });
});
