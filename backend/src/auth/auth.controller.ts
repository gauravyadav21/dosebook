import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Public } from './auth.decorators.js';
import { CredentialsDto, TokenDto } from './auth.dto.js';
import { AuthService } from './auth.service.js';

const authLimit = () => Number(process.env.AUTH_THROTTLE_LIMIT ?? 10);

@ApiTags('auth')
@Public()
// Tighter limit than the rest of the API to slow down password guessing.
@Throttle({ default: { ttl: 60_000, limit: authLimit } })
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  @ApiCreatedResponse({ type: TokenDto })
  register(@Body() dto: CredentialsDto): Promise<TokenDto> {
    return this.auth.register(dto);
  }

  @Post('login')
  @HttpCode(200)
  @ApiOkResponse({ type: TokenDto })
  login(@Body() dto: CredentialsDto): Promise<TokenDto> {
    return this.auth.login(dto);
  }
}
