import { hashPassword, verifyPassword } from '../auth/password.js';
import { sniffMime } from '../documents/file-type.js';
import { loadConfig } from './config.js';
import { addDays, diffDays, isCalendarDate } from './dates.js';

describe('dates', () => {
  it.each(['2026-10-04', '2024-02-29', '2026-12-31'])('accepts %s', (d) => {
    expect(isCalendarDate(d)).toBe(true);
  });
  it.each(['2026-02-30', '2025-02-29', '2026-13-01', '04-10-2026', '2026-1-4', '', null, 20261004])('rejects %j', (d) => {
    expect(isCalendarDate(d)).toBe(false);
  });
  it('adds days across month ends and leap days', () => {
    expect(addDays('2026-01-30', 3)).toBe('2026-02-02');
    expect(addDays('2024-02-28', 2)).toBe('2024-03-01');
    expect(addDays('2026-03-01', -1)).toBe('2026-02-28');
  });
  it('counts whole days between dates', () => {
    expect(diffDays('2026-10-01', '2026-10-06')).toBe(5);
    expect(diffDays('2026-10-06', '2026-10-01')).toBe(-5);
    expect(diffDays('2026-03-28', '2026-03-30')).toBe(2);
  });
});

describe('password hashing', () => {
  it('verifies the right password and rejects a wrong one', async () => {
    const hash = await hashPassword('correct-horse-battery');
    expect(await verifyPassword('correct-horse-battery', hash)).toBe(true);
    expect(await verifyPassword('correct-horse-batterx', hash)).toBe(false);
  });
  it('salts: the same password hashes differently each time', async () => {
    expect(await hashPassword('same-password')).not.toBe(await hashPassword('same-password'));
  });
  it.each(['', 'plain-text', 'bcrypt$aa$bb', 'scrypt$$'])('rejects a malformed stored value %j', async (stored) => {
    expect(await verifyPassword('anything', stored)).toBe(false);
  });
});

describe('sniffMime', () => {
  it('detects JPEG, PNG and PDF from their first bytes', () => {
    expect(sniffMime(Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0]))).toBe('image/jpeg');
    expect(sniffMime(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0]))).toBe('image/png');
    expect(sniffMime(Buffer.from('%PDF-1.7\n'))).toBe('application/pdf');
  });
  it.each([
    ['empty', Buffer.alloc(0)],
    ['text', Buffer.from('hello world')],
    ['html', Buffer.from('<html><script>alert(1)</script>')],
    ['gif', Buffer.from('GIF89a')],
    ['zip/docx', Buffer.from([0x50, 0x4b, 0x03, 0x04])],
    ['truncated png', Buffer.from([0x89, 0x50, 0x4e])],
  ])('rejects %s', (_label, data) => {
    expect(sniffMime(data)).toBeNull();
  });
});

describe('loadConfig', () => {
  const saved = { ...process.env };
  afterEach(() => {
    process.env = { ...saved };
  });

  it('fails fast when a required variable is missing', () => {
    delete process.env.JWT_SECRET;
    process.env.DATABASE_URL = 'postgresql://example';
    expect(() => loadConfig()).toThrow('JWT_SECRET');
  });

  it('treats an empty Gemini key as not set', () => {
    process.env.DATABASE_URL = 'postgresql://example';
    process.env.JWT_SECRET = 'unit-test-value';
    process.env.GEMINI_API_KEY = '';
    expect(loadConfig().geminiApiKey).toBeUndefined();
  });
});
