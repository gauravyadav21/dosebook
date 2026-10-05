# Coding standards

## Both
- Small changes. Run lint or analyze and the tests before every commit.
- Fake data only in code, tests, seeds and screenshots.
- No secrets, URLs with credentials or keys in code. Configuration comes from the environment.
- A comment says why, or states a rule the code must keep (for example "never shown as prescribed"). It does not restate the code.
- User-facing doctor-vs-app wording lives in one place per side (`backend/src/chat/chat.rules.ts`, `mobile/lib/app/wording.dart`) and matches `docs/01-requirements/what-we-do-and-dont.md`.

## Backend (NestJS)
- One folder per feature under `backend/src/`. One application; no separate services.
- Every request body and query is a DTO class with `class-validator` rules. The global pipe rejects unknown fields. A nested object needs `@IsDefined()` as well as `@ValidateNested()`.
- Every query filters by the signed-in user's id. Another user's record returns 404, never 403.
- Logic that can be a pure function is one (`*.logic.ts`, `*.rules.ts`, `doctor-match.ts`) with a unit test beside it. Controllers stay thin.
- Schema changes go through a Prisma migration. Never edit an applied migration.
- Lint: `oxlint --type-aware`. Format: Prettier. Tests: Vitest (`*.spec.ts` unit, `test/*.e2e-spec.ts` against a real PostgreSQL).

## Mobile (Flutter)
- Feature-first folders under `mobile/lib/features/`. Shared widgets in `lib/widgets/`.
- `flutter analyze` clean.
- State: `ChangeNotifier` for the session, `setState` inside a screen. No state-management package.
- All server calls go through `lib/api/api.dart`. Screens show the server's error message; they do not fail silently.
- Every screen that shows server data loads through `Loader` (`lib/widgets/common.dart`). That gives it pull-to-refresh, a reload when data changes anywhere in the app, and a reload when the app returns to the foreground. No fetching in `initState` and no manual reload after navigation. See the `add-screen` skill.
- Phone features (file picker, dialler, share sheet, notifications) sit behind a replaceable function or interface so widget tests can run without them.
- Colours and text styles come from the theme (`ColorScheme.fromSeed`), never hard-coded hex values.
