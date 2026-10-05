import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service.js';
import type { CredentialsDto, TokenDto } from './auth.dto.js';
import { hashPassword, verifyPassword } from './password.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register({ email, password }: CredentialsDto): Promise<TokenDto> {
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('An account with this email already exists');
    const user = await this.prisma.user.create({
      data: { email, passwordHash: await hashPassword(password) },
    });
    return this.issue(user.id);
  }

  async login({ email, password }: CredentialsDto): Promise<TokenDto> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    // Same message for unknown email and wrong password, so accounts cannot be probed.
    if (!user || !(await verifyPassword(password, user.passwordHash))) {
      throw new UnauthorizedException('Email or password is incorrect');
    }
    return this.issue(user.id);
  }

  private async issue(userId: string): Promise<TokenDto> {
    return { accessToken: await this.jwt.signAsync({ sub: userId }) };
  }
}
