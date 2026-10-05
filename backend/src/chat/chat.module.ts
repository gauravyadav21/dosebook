import { Module } from '@nestjs/common';
import { MedicineInfoModule } from '../medicine-info/medicine-info.module.js';
import { ChatController } from './chat.controller.js';

@Module({ imports: [MedicineInfoModule], controllers: [ChatController] })
export class ChatModule {}
