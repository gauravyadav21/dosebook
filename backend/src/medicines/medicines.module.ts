import { Module } from '@nestjs/common';
import { MedicinesController } from './medicines.controller.js';

@Module({ controllers: [MedicinesController] })
export class MedicinesModule {}
