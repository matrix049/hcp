/**
 * The single output contract every LLM provider must satisfy.
 *
 * Whichever engine answers, the SHAPE is identical: the model is held to this
 * schema, and `normalizeSurvey()` repairs whatever slips through. The Flutter
 * app can therefore never receive a malformed survey, whether it came from the
 * model or from the keyword heuristic.
 */

/** The only question types the Flutter app actually renders today. */
export const RENDERED_TYPES = ['text', 'number', 'radio', 'checkbox', 'dropdown', 'date'];

/** Types that must carry an options list. */
const CHOICE_TYPES = ['radio', 'checkbox', 'dropdown'];

const localized = {
  type: 'object',
  properties: { fr: { type: 'string' }, ar: { type: 'string' } },
  required: ['fr', 'ar'],
};

/** Canonical JSON schema — each provider adapts this to its own dialect. */
export const SURVEY_SCHEMA = {
  type: 'object',
  properties: {
    title: localized,
    questions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          type: { type: 'string', enum: RENDERED_TYPES },
          label: localized,
          required: { type: 'boolean' },
          multiline: { type: 'boolean' },
          help: localized,
          validation: {
            type: 'object',
            properties: { min: { type: 'number' }, max: { type: 'number' } },
          },
          options: {
            type: 'array',
            items: {
              type: 'object',
              properties: { value: { type: 'string' }, label: localized },
              required: ['value', 'label'],
            },
          },
        },
        // `help` is required, not optional: left optional, models skip it on the
        // questions they consider self-evident, and the field agent loses the
        // offline explanation exactly where the form is hardest to fill.
        required: ['id', 'type', 'label', 'required', 'help'],
      },
    },
  },
  required: ['title', 'questions'],
};

/** URL/DB-safe option value: lowercase, unaccented, underscores. */
export function slug(s) {
  return (
    String(s ?? '')
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '')
      .slice(0, 40) || 'opt'
  );
}

function cleanLocalized(value, fallback = '') {
  const fr = typeof value?.fr === 'string' ? value.fr.trim() : '';
  const ar = typeof value?.ar === 'string' ? value.ar.trim() : '';
  if (!fr && !ar) return fallback ? { fr: fallback, ar: '' } : null;
  return { fr: fr || fallback || ar, ar };
}

/**
 * Repair anything the model got structurally wrong, and record what we fixed.
 * This runs on EVERY provider's output, including the heuristic's.
 *
 * Returns { survey, repairs } where `repairs` is a list of human-readable notes
 * shown to the admin on the review screen.
 */
export function normalizeSurvey(raw, { fallbackTitle = 'Enquête générée' } = {}) {
  const repairs = [];
  const title = cleanLocalized(raw?.title, fallbackTitle) ?? { fr: fallbackTitle, ar: '' };

  const input = Array.isArray(raw?.questions) ? raw.questions : [];
  const questions = [];

  input.forEach((q, i) => {
    const position = i + 1;
    const label = cleanLocalized(q?.label);
    if (!label) {
      repairs.push(`Question ${position} ignorée : libellé vide.`);
      return;
    }

    let type = String(q?.type ?? '').toLowerCase();
    if (!RENDERED_TYPES.includes(type)) {
      repairs.push(`Question ${position} : type "${q?.type}" non supporté → text.`);
      type = 'text';
    }

    // Options: required for choice types, meaningless elsewhere.
    let options;
    if (Array.isArray(q?.options) && q.options.length > 0) {
      const seen = new Set();
      options = [];
      for (const o of q.options) {
        const optLabel = cleanLocalized(o?.label) ?? cleanLocalized({ fr: o?.value });
        if (!optLabel) continue;
        let value = slug(o?.value || optLabel.fr);
        while (seen.has(value)) value = `${value}_2`;
        seen.add(value);
        options.push({ value, label: optLabel });
      }
      if (options.length === 0) options = undefined;
    }

    if (CHOICE_TYPES.includes(type) && !options) {
      repairs.push(`Question ${position} : type "${type}" sans options → text.`);
      type = 'text';
    }
    if (!CHOICE_TYPES.includes(type) && options) {
      repairs.push(`Question ${position} : options retirées (type "${type}").`);
      options = undefined;
    }

    const question = {
      id: `q_${questions.length + 1}`,
      type,
      label,
      required: q?.required !== false,
    };
    if (options) question.options = options;

    // multiline only means something on free text.
    if (type === 'text' && q?.multiline === true) question.multiline = true;

    // validation only means something on numbers. Gemini likes to attach a
    // stray {min:0} to text questions — drop it silently rather than noisily,
    // it is a model tic, not an admin-visible mistake.
    if (type === 'number' && q?.validation && typeof q.validation === 'object') {
      const v = {};
      if (Number.isFinite(q.validation.min)) v.min = q.validation.min;
      if (Number.isFinite(q.validation.max)) v.max = q.validation.max;
      if (Number.isFinite(v.min) && Number.isFinite(v.max) && v.min > v.max) {
        repairs.push(`Question ${position} : validation min > max, corrigée.`);
        [v.min, v.max] = [v.max, v.min];
      }
      if (Object.keys(v).length > 0) question.validation = v;
    }

    const help = cleanLocalized(q?.help);
    if (help) question.help = help;

    questions.push(question);
  });

  return { survey: { title, questions }, repairs };
}

/**
 * Wrap the normalized {title, questions} into the survey definition the
 * Flutter app downloads (id / version / locales / pages).
 */
export function toSurveyDefinition({ title, questions }, { id, version = 1 } = {}) {
  const hasArabic =
    (title.ar && title.ar.length > 0) || questions.some((q) => q.label.ar?.length > 0);
  return {
    id: id || `survey_generated_${Date.now()}`,
    version,
    title,
    locales: hasArabic ? ['fr', 'ar'] : ['fr'],
    pages: [{ id: 'page_1', title, questions }],
  };
}
