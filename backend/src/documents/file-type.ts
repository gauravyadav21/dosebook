export const MAX_FILE_BYTES = 10 * 1024 * 1024;

export type AllowedMime = 'image/jpeg' | 'image/png' | 'application/pdf';

const EXTENSIONS: Record<AllowedMime, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'application/pdf': 'pdf',
};

/** Detects the type from the file's first bytes. The client-supplied name and MIME type are not trusted. */
export function sniffMime(data: Buffer): AllowedMime | null {
  if (data.length >= 3 && data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff) return 'image/jpeg';
  if (data.length >= 8 && data.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
    return 'image/png';
  }
  if (data.length >= 5 && data.subarray(0, 5).toString('latin1') === '%PDF-') return 'application/pdf';
  return null;
}

export function extensionFor(mime: AllowedMime): string {
  return EXTENSIONS[mime];
}
