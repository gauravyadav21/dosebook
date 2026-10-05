import { Module } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../common/config.js';
import { GeminiMedicineInfo } from './gemini-medicine-info.js';
import { MEDICINE_INFO_PROVIDER, type MedicineInfoProvider } from './medicine-info.js';
import { MedicineInfoService } from './medicine-info.service.js';

@Module({
  providers: [
    {
      provide: MEDICINE_INFO_PROVIDER,
      inject: [APP_CONFIG],
      // Without a key there is no provider: lookups answer from the saved table only.
      useFactory: (config: AppConfig): MedicineInfoProvider | null =>
        config.geminiApiKey ? new GeminiMedicineInfo(config.geminiApiKey, config.geminiModels) : null,
    },
    MedicineInfoService,
  ],
  exports: [MedicineInfoService],
})
export class MedicineInfoModule {}
