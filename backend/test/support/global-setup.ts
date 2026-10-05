import { execSync } from 'node:child_process';
import { rmSync } from 'node:fs';

/** Brings the test database up to the current migrations before any e2e file runs. */
export default function setup() {
  const url = process.env.TEST_DATABASE_URL ?? 'postgresql://app@localhost:54329/dosebook_test';
  execSync('npx prisma migrate deploy', { env: { ...process.env, DATABASE_URL: url }, stdio: 'pipe' });
  return () => rmSync('./.e2e-uploads', { recursive: true, force: true });
}
