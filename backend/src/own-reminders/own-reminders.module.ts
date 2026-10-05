import { Module } from '@nestjs/common';
import { OwnRemindersController } from './own-reminders.controller.js';

@Module({ controllers: [OwnRemindersController] })
export class OwnRemindersModule {}
