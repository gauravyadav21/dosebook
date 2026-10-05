import { Module } from '@nestjs/common';
import { NotesController } from './notes.controller.js';

@Module({ controllers: [NotesController] })
export class NotesModule {}
