import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    globals: true,
    root: './',
    include: ['**/*.e2e-spec.ts'],
    globalSetup: ['./test/support/global-setup.ts'],
    testTimeout: 20_000,
    // Test-only values. The database is the local throwaway one from scripts/dev-db.sh (or the CI service).
    env: {
      DATABASE_URL: process.env.TEST_DATABASE_URL ?? 'postgresql://app@localhost:54329/dosebook_test',
      JWT_SECRET: 'e2e-only-signing-value',
      UPLOAD_DIR: './.e2e-uploads',
      THROTTLE_LIMIT: '100000',
      AUTH_THROTTLE_LIMIT: '100000',
      CHAT_THROTTLE_LIMIT: '100000',
      GEMINI_API_KEY: '',
    },
  },
});
