import { type INestApplication, ValidationPipe } from '@nestjs/common';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

/** Shared by main.ts and e2e tests so tests exercise the real pipeline. */
export function configureApp(app: INestApplication): INestApplication {
  // Behind a hosting proxy every request arrives from the proxy's address. Trusting exactly one hop
  // makes the rate limit count per visitor again. Off unless set: without a proxy the header could be forged.
  if (process.env.TRUST_PROXY === 'true') {
    (app as NestExpressApplication).set('trust proxy', 1);
  }

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('DoseBook API')
    .setDescription('Recall and remind. The API never prescribes: it only returns what the user confirmed or noted.')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, config));

  return app;
}
