/**
 * A provider failure, tagged with WHY — the ladder uses `kind` to decide whether
 * falling back to the next engine is legitimate.
 */
export class LlmError extends Error {
  constructor(provider, kind, message) {
    super(`[${provider}/${kind}] ${message}`);
    this.name = 'LlmError';
    this.provider = provider;
    this.kind = kind;
  }

  /**
   * `bad_request` and `bad_json` mean our own request or parsing is wrong.
   * Falling back would mask a bug we need to see, so those do NOT cascade.
   */
  get shouldFallback() {
    return !['bad_request'].includes(this.kind);
  }
}
