import Anthropic from '@anthropic-ai/sdk';

import { env } from '../../../../config/env.js';
import { SURVEY_SCHEMA } from '../schema.js';
import { LlmError } from '../errors.js';

/**
 * Anthropic Claude — the premium tier.
 *
 * Inactive until ANTHROPIC_API_KEY is set; the ladder then picks it first with
 * no other change. Note a Claude Max/Pro subscription does NOT grant API
 * access — the API is billed separately (pay-as-you-go credits).
 *
 * Structured output uses STRICT TOOL USE rather than Zod, so the exact same
 * plain JSON schema object serves both providers.
 */
const MODEL = 'claude-opus-5';

/** Strict tool use requires additionalProperties:false on every object node. */
function toStrictSchema(schema) {
  if (Array.isArray(schema)) return schema.map(toStrictSchema);
  if (schema && typeof schema === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(schema)) out[k] = toStrictSchema(v);
    if (out.type === 'object' && out.properties) {
      out.additionalProperties = false;
      out.required = Object.keys(out.properties);
    }
    return out;
  }
  return schema;
}

let client;
function getClient() {
  client ??= new Anthropic({ apiKey: env.llm.anthropicApiKey, maxRetries: 2 });
  return client;
}

export const claude = {
  name: 'claude',
  get available() {
    return Boolean(env.llm.anthropicApiKey);
  },

  async generate({ system, user }) {
    if (!this.available) throw new LlmError('claude', 'no_key', 'ANTHROPIC_API_KEY is not set');

    // `required` on a strict schema must list every property, so optional
    // fields are expressed as nullable rather than absent.
    const inputSchema = toStrictSchema({
      ...SURVEY_SCHEMA,
      properties: {
        ...SURVEY_SCHEMA.properties,
        questions: {
          ...SURVEY_SCHEMA.properties.questions,
          items: {
            ...SURVEY_SCHEMA.properties.questions.items,
            properties: {
              ...SURVEY_SCHEMA.properties.questions.items.properties,
              multiline: { type: ['boolean', 'null'] },
              help: { type: ['object', 'null'], properties: { fr: { type: 'string' }, ar: { type: 'string' } } },
              validation: {
                type: ['object', 'null'],
                properties: { min: { type: ['number', 'null'] }, max: { type: ['number', 'null'] } },
              },
              options: { type: ['array', 'null'], items: SURVEY_SCHEMA.properties.questions.items.properties.options.items },
            },
          },
        },
      },
    });

    try {
      const response = await getClient().messages.create({
        model: MODEL,
        max_tokens: 16000,
        thinking: { type: 'adaptive' },
        system,
        messages: [{ role: 'user', content: user }],
        tools: [
          {
            name: 'emit_survey',
            description: "Renvoie le questionnaire structuré extrait du document.",
            strict: true,
            input_schema: inputSchema,
          },
        ],
        tool_choice: { type: 'tool', name: 'emit_survey' },
      });

      if (response.stop_reason === 'refusal') {
        throw new LlmError('claude', 'refusal', response.stop_details?.explanation ?? 'refused');
      }
      const block = response.content.find((b) => b.type === 'tool_use');
      if (!block) throw new LlmError('claude', 'empty', 'no tool_use block in response');

      return { data: block.input, engine: `claude:${MODEL}` };
    } catch (err) {
      if (err instanceof LlmError) throw err;
      const status = err?.status;
      if (status === 400) throw new LlmError('claude', 'bad_request', err.message);
      if (status === 401 || status === 403) throw new LlmError('claude', 'auth', err.message);
      if (status === 429) throw new LlmError('claude', 'quota', err.message);
      throw new LlmError('claude', 'unavailable', err?.message ?? String(err));
    }
  },
};
