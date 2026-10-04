import { z } from 'zod';

/**
 * All runtime configuration is validated once at boot. If a required secret is missing the
 * process fails fast with a clear message instead of surfacing a confusing error deep in a
 * request handler later.
 */
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),

  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  JWT_ACCESS_SECRET: z.string().min(16, 'JWT_ACCESS_SECRET must be set to a long random value'),
  JWT_REFRESH_SECRET: z.string().min(16, 'JWT_REFRESH_SECRET must be set to a long random value'),
  JWT_ACCESS_TTL: z.string().default('15m'),
  JWT_REFRESH_TTL: z.string().default('30d'),

  CORS_ALLOWED_ORIGINS: z.string().default(''),

  OCR_PROVIDER: z.enum(['google-vision', 'groq', 'mock']).default('google-vision'),
  GOOGLE_CLOUD_PROJECT_ID: z.string().optional(),
  GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE64: z.string().optional(),

  BARCODE_PROVIDER: z.enum(['open-food-facts', 'mock']).default('open-food-facts'),
  OPEN_FOOD_FACTS_BASE_URL: z.string().url().default('https://world.openfoodfacts.org'),

  AI_PROVIDER: z.enum(['anthropic', 'groq', 'mock']).default('anthropic'),
  ANTHROPIC_API_KEY: z.string().optional(),
  ANTHROPIC_MODEL: z.string().default('claude-sonnet-5'),

  // Groq (groq.com — fast inference for open models, OpenAI-compatible API). Not to be confused
  // with xAI's "Grok" model; distinct service, distinct key format (gsk_...).
  GROQ_API_KEY: z.string().optional(),
  GROQ_BASE_URL: z.string().url().default('https://api.groq.com/openai/v1'),
  // Groq's catalog is account-specific and changes over time — these are defaults, not
  // guarantees; verify with GET {GROQ_BASE_URL}/models against your own key if either 404s.
  GROQ_MODEL: z.string().default('openai/gpt-oss-120b'),
  GROQ_VISION_MODEL: z.string().default('qwen/qwen3.8-27b'),

  TTS_PROVIDER: z.enum(['google-cloud-tts', 'mock']).default('google-cloud-tts'),
  STT_PROVIDER: z.enum(['google-cloud-stt', 'mock']).default('google-cloud-stt'),

  RETAIN_SCAN_IMAGES: z
    .string()
    .default('false')
    .transform((v) => v === 'true'),

  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60_000),
  RATE_LIMIT_MAX_REQUESTS: z.coerce.number().int().positive().default(60),
});

export type AppConfig = z.infer<typeof envSchema> & {
  corsAllowedOrigins: string[];
  isProduction: boolean;
  isTest: boolean;
};

let cached: AppConfig | null = null;

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  if (cached) return cached;

  const parsed = envSchema.safeParse(env);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((i) => `  - ${i.path.join('.')}: ${i.message}`)
      .join('\n');
    // eslint-disable-next-line no-console
    console.error(`Invalid environment configuration:\n${issues}`);
    throw new Error('Invalid environment configuration. See stderr for details.');
  }

  const data = parsed.data;

  if (data.AI_PROVIDER === 'anthropic' && !data.ANTHROPIC_API_KEY && data.NODE_ENV !== 'test') {
    throw new Error('ANTHROPIC_API_KEY is required when AI_PROVIDER=anthropic');
  }
  if (
    data.OCR_PROVIDER === 'google-vision' &&
    !data.GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE64 &&
    data.NODE_ENV !== 'test'
  ) {
    throw new Error(
      'GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE64 is required when OCR_PROVIDER=google-vision',
    );
  }
  if ((data.AI_PROVIDER === 'groq' || data.OCR_PROVIDER === 'groq') && !data.GROQ_API_KEY && data.NODE_ENV !== 'test') {
    throw new Error('GROQ_API_KEY is required when AI_PROVIDER=groq or OCR_PROVIDER=groq');
  }

  cached = {
    ...data,
    corsAllowedOrigins: data.CORS_ALLOWED_ORIGINS.split(',')
      .map((s) => s.trim())
      .filter(Boolean),
    isProduction: data.NODE_ENV === 'production',
    isTest: data.NODE_ENV === 'test',
  };
  return cached;
}

/** Test-only: clears the cached config so tests can reload with different env vars. */
export function _resetConfigForTests(): void {
  cached = null;
}
