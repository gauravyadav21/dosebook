import { Body, Controller, Get, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiConflictResponse, ApiTags } from '@nestjs/swagger';
import { UserId } from '../auth/auth.decorators.js';
import { ConfirmDto } from './prescriptions.dto.js';
import { PrescriptionsService } from './prescriptions.service.js';

@ApiTags('prescriptions')
@ApiBearerAuth()
@Controller()
export class PrescriptionsController {
  constructor(private readonly prescriptions: PrescriptionsService) {}

  @Post('documents/:id/confirm')
  @ApiConflictResponse({ description: 'Already confirmed, or code DOCTOR_NAME_MATCH: resend with sameDoctorId or newDoctor.' })
  confirm(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string, @Body() dto: ConfirmDto) {
    return this.prescriptions.confirm(userId, id, dto);
  }

  /** Timeline: confirmed prescriptions, newest first. */
  @Get('prescriptions')
  list(@UserId() userId: string) {
    return this.prescriptions.list(userId);
  }

  @Get('prescriptions/:id')
  get(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.prescriptions.get(userId, id);
  }
}
