import { Module } from '@nestjs/common';
import { AllergiesController } from './allergies.controller.js';

@Module({ controllers: [AllergiesController] })
export class AllergiesModule {}
