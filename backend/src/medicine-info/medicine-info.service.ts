import { Inject, Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { MEDICINE_INFO_PROVIDER, medicineKey, type MedicineInfoProvider } from './medicine-info.js';

export type GeneralInfo =
  | { found: true; name: string; usedFor: string; storage: string | null }
  | { found: false; reason: 'NOT_A_MEDICINE' | 'UNKNOWN' };

@Injectable()
export class MedicineInfoService {
  private readonly logger = new Logger(MedicineInfoService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(MEDICINE_INFO_PROVIDER) private readonly provider: MedicineInfoProvider | null,
  ) {}

  /**
   * Our own table first. The model is asked only when the medicine is not saved yet,
   * and its answer is saved so the same medicine is never looked up twice.
   */
  async find(name: string): Promise<GeneralInfo> {
    const nameKey = medicineKey(name);
    if (!nameKey) return { found: false, reason: 'UNKNOWN' };

    const saved = await this.prisma.medicineInfo.findUnique({ where: { nameKey } });
    if (saved) return { found: true, name: saved.name, usedFor: saved.summary, storage: saved.storage };
    if (!this.provider) return { found: false, reason: 'UNKNOWN' };

    try {
      const result = await this.provider.lookup(name);
      if (!result) return { found: false, reason: 'UNKNOWN' };
      if (!result.isMedicine) return { found: false, reason: 'NOT_A_MEDICINE' };
      // Two people may ask about the same new medicine at once; the second write is a no-op.
      await this.prisma.medicineInfo.upsert({
        where: { nameKey },
        create: { nameKey, name: result.name, summary: result.usedFor, storage: result.storage, source: 'GEMINI' },
        update: {},
      });
      return { found: true, name: result.name, usedFor: result.usedFor, storage: result.storage };
    } catch (error) {
      this.logger.warn(`Medicine lookup failed: ${(error as Error).message}`);
      return { found: false, reason: 'UNKNOWN' };
    }
  }
}
