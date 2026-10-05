import { Body, Controller, Delete, Get, HttpCode, NotFoundException, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';
import { UserId } from '../auth/auth.decorators.js';
import { PrismaService } from '../prisma/prisma.service.js';

export class AllergyDto {
  @ApiProperty({ example: 'Penicillin' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value))
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  name: string;
}

@ApiTags('allergies')
@ApiBearerAuth()
@Controller('allergies')
export class AllergiesController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async list(@UserId() userId: string) {
    const rows = await this.prisma.allergy.findMany({ where: { userId }, orderBy: { createdAt: 'asc' } });
    return rows.map(({ id, name }) => ({ id, name }));
  }

  /** Adding the same allergy twice returns the existing entry. Matching medicines are excluded from chat at once (S4). */
  @Post()
  async add(@UserId() userId: string, @Body() dto: AllergyDto) {
    const existing = await this.prisma.allergy.findFirst({
      where: { userId, name: { equals: dto.name, mode: 'insensitive' } },
    });
    const row = existing ?? (await this.prisma.allergy.create({ data: { userId, name: dto.name } }));
    return { id: row.id, name: row.name };
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@UserId() userId: string, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    const { count } = await this.prisma.allergy.deleteMany({ where: { id, userId } });
    if (count === 0) throw new NotFoundException('Allergy not found');
  }
}
