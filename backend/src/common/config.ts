/** Reads configuration from the environment. Names are listed in docs/05-delivery/env-vars.md. */
export interface AppConfig {
  databaseUrl: string;
  jwtSecret: string;
  jwtExpiresIn: string;
  uploadDir: string;
  /** Where uploaded files are kept: on disk, or in the database for hosts whose disk does not last. */
  fileStorage: 'disk' | 'database';
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

function fileStorage(): AppConfig['fileStorage'] {
  const value = process.env.FILE_STORAGE || 'disk';
  if (value !== 'disk' && value !== 'database') {
    throw new Error('FILE_STORAGE must be disk or database');
  }
  return value;
}

export function loadConfig(): AppConfig {
  return {
    databaseUrl: required('DATABASE_URL'),
    jwtSecret: required('JWT_SECRET'),
    jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
    uploadDir: process.env.UPLOAD_DIR ?? './uploads',
    fileStorage: fileStorage(),
    throttleLimit: Number(process.env.THROTTLE_LIMIT ?? 120),
    authThrottleLimit: Number(process.env.AUTH_THROTTLE_LIMIT ?? 10),
    geminiApiKey: process.env.GEMINI_API_KEY || undefined,
    // Aliases that Google keeps pointing at its current models, so a retired version does not break the app.
    geminiModels: [process.env.GEMINI_MODEL || 'gemini-flash-latest', process.env.GEMINI_FALLBACK_MODEL || 'gemini-flash-lite-latest'],
  };
}

export const APP_CONFIG = Symbol('APP_CONFIG');
