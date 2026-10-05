import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AllergiesModule } from './allergies/allergies.module.js';
import { AuthGuard } from './auth/auth.guard.js';
import { AuthModule } from './auth/auth.module.js';
import { ChatModule } from './chat/chat.module.js';
import { ConfigModule } from './common/config.module.js';
import { DoctorsModule } from './doctors/doctors.module.js';
import { DocumentsModule } from './documents/documents.module.js';
import { DosesModule } from './doses/doses.module.js';
import { HealthController } from './health/health.controller.js';
import { MeController } from './me/me.controller.js';
import { MedicinesModule } from './medicines/medicines.module.js';
import { NotesModule } from './notes/notes.module.js';
import { OwnRemindersModule } from './own-reminders/own-reminders.module.js';
import { PrescriptionsModule } from './prescriptions/prescriptions.module.js';
import { PrismaModule } from './prisma/prisma.module.js';

@Module({
  imports: [
    ConfigModule,
    PrismaModule,
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: () => Number(process.env.THROTTLE_LIMIT ?? 120) }]),
    AuthModule,
    DocumentsModule,
    PrescriptionsModule,
    MedicinesModule,
    AllergiesModule,
    DosesModule,
    NotesModule,
    OwnRemindersModule,
    ChatModule,
    DoctorsModule,
  ],
  controllers: [HealthController, MeController],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    // Every route needs a valid token unless marked @Public().
    { provide: APP_GUARD, useExisting: AuthGuard },
  ],
})
export class AppModule {}
