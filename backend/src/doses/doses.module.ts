import { Module } from '@nestjs/common';
import { DosesController } from './doses.controller.js';

@Module({ controllers: [DosesController] })
export class DosesModule {}
