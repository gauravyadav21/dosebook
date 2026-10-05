import { Module } from '@nestjs/common';
import { DoctorsController } from './doctors.controller.js';

@Module({ controllers: [DoctorsController] })
export class DoctorsModule {}
