/** Reads configuration from the environment. Names are listed in docs/05-delivery/env-vars.md. */
export interface AppConfig {
  databaseUrl: string;
  jwtSecret: string;
  jwtExpiresIn: string;
  uploadDir: string;
  throttleLimit: number;
  authThrottleLimit: number;
  geminiApiKey?: string;
  /** Tried in order: the second is used when the first is retired, over quota or overloaded. */
  geminiModels: string[];
}

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable ${name}`);
  }
  return value;
}

export function loadConfig(): AppConfig {
  return {
    databaseUrl: required('DATABASE_URL'),
    jwtSecret: required('JWT_SECRET'),
    jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
    uploadDir: process.env.UPLOAD_DIR ?? './uploads',
    throttleLimit: Number(process.env.THROTTLE_LIMIT ?? 120),
    authThrottleLimit: Number(process.env.AUTH_THROTTLE_LIMIT ?? 10),
    geminiApiKey: process.env.GEMINI_API_KEY || undefined,
    // Aliases that Google keeps pointing at its current models, so a retired version does not break the app.
    geminiModels: [process.env.GEMINI_MODEL || 'gemini-flash-latest', process.env.GEMINI_FALLBACK_MODEL || 'gemini-flash-lite-latest'],
  };
}

export const APP_CONFIG = Symbol('APP_CONFIG');
