import { createParamDecorator, type ExecutionContext, SetMetadata } from '@nestjs/common';

export const IS_PUBLIC = 'isPublic';

/** Marks a route as reachable without a token. Everything else requires one. */
export const Public = () => SetMetadata(IS_PUBLIC, true);

/** Id of the signed-in user, set by AuthGuard. */
export const UserId = createParamDecorator((_data: unknown, ctx: ExecutionContext): string => {
  return ctx.switchToHttp().getRequest().userId;
});
