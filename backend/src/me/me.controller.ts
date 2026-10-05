import { BadRequestException, Body, Controller, Get, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsInt } from 'class-validator';
import { UserId } from '../auth/auth.decorators.js';
import { todayUtc } from '../common/dates.js';
import type { User } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ProfileDto } from './profile.dto.js';

/** Bump when the first-run "what this app is and is not" wording changes; users must acknowledge again (S8). */
export const ACK_VERSION = 1;

export class AcknowledgeDto {
  @ApiProperty({ example: ACK_VERSION })
  @IsInt()
  version: number;
}

function toProfile(user: User) {
  return {
    email: user.email,
    name: user.name,
    dateOfBirth: user.dateOfBirth,
    sex: user.sex,
    heightCm: user.heightCm,
    weightKg: user.weightKg,
    bloodGroup: user.bloodGroup,
    emergencyName: user.emergencyName,
    emergencyPhone: user.emergencyPhone,
    conditions: user.conditions,
  };
}

@ApiTags('me')
@ApiBearerAuth()
@Controller('me')
export class MeController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async me(@UserId() userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    return {
      id: user.id,
      email: user.email,
      acknowledgement: {
        currentVersion: ACK_VERSION,
        acknowledgedVersion: user.ackVersion,
        required: user.ackVersion !== ACK_VERSION,
      },
    };
  }

  @Put('acknowledgement')
  async acknowledge(@UserId() userId: string, @Body() dto: AcknowledgeDto) {
    if (dto.version !== ACK_VERSION) {
      throw new BadRequestException(`Only the current wording (version ${ACK_VERSION}) can be acknowledged`);
    }
    await this.prisma.user.update({ where: { id: userId }, data: { ackVersion: ACK_VERSION, ackAt: new Date() } });
    return this.me(userId);
  }

  @Get('profile')
  async profile(@UserId() userId: string) {
    return toProfile(await this.prisma.user.findUniqueOrThrow({ where: { id: userId } }));
  }

  /** Replaces the profile. The app stores these details and never advises from them (S10). */
  @Put('profile')
  async saveProfile(@UserId() userId: string, @Body() dto: ProfileDto) {
    if (dto.dateOfBirth && (dto.dateOfBirth > todayUtc() || dto.dateOfBirth < '1900-01-01')) {
      throw new BadRequestException('dateOfBirth must be between 1900 and today');
    }
    const text = (value: string | null | undefined) => value?.trim() || null;
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        name: text(dto.name),
        dateOfBirth: dto.dateOfBirth ?? null,
        sex: dto.sex ?? null,
        heightCm: dto.heightCm ?? null,
        weightKg: dto.weightKg ?? null,
        bloodGroup: dto.bloodGroup ?? null,
        emergencyName: text(dto.emergencyName),
        emergencyPhone: text(dto.emergencyPhone),
        conditions: text(dto.conditions),
      },
    });
    return toProfile(user);
  }
}
