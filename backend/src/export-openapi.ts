import { writeFileSync } from 'node:fs';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module.js';

/** Writes the OpenAPI document to the path given as the first argument. Run after `npm run build`. */
const app = await NestFactory.create(AppModule, { logger: false });
const config = new DocumentBuilder()
  .setTitle('DoseBook API')
  .setDescription('Recall and remind. The API never prescribes: it only returns what the user confirmed or noted.')
  .setVersion('0.1.0')
  .addBearerAuth()
  .build();
const target = process.argv[2] ?? 'openapi.json';
writeFileSync(target, `${JSON.stringify(SwaggerModule.createDocument(app, config), null, 2)}\n`);
await app.close();
