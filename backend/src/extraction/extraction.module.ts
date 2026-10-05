import { Module } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../common/config.js';
import { DemoExtractor } from './demo.extractor.js';
import { EXTRACTOR, type Extractor } from './extraction.types.js';
import { GeminiExtractor } from './gemini.extractor.js';

@Module({
  providers: [
    {
      provide: EXTRACTOR,
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig): Extractor =>
        config.geminiApiKey ? new GeminiExtractor(config.geminiApiKey, config.geminiModels) : new DemoExtractor(),
    },
  ],
  exports: [EXTRACTOR],
})
export class ExtractionModule {}
