# Backend

NestJS + Prisma + PostgreSQL. One application, a folder per feature under `src/`. Requires Node 20.19 or newer.

## Run locally
```
npm ci                      # also generates the Prisma client
npm run db:start            # local PostgreSQL on port 54329 (uses an installed PostgreSQL 15+, no Docker)
cp .env.example .env        # then fill DATABASE_URL and JWT_SECRET; never commit .env
npm run db:migrate
npm run start:dev           # http://localhost:3000, Swagger at /docs, health at /health
```
`DATABASE_URL` for the local database: `postgresql://app@localhost:54329/dosebook_app`.
`npm run db:stop` stops the database. `scripts/dev-db.sh reset` deletes it.

## Check
```
npm run lint && npm run build && npm test && npm run test:e2e
```
End-to-end tests use the `dosebook_test` database from `db:start` (override with `TEST_DATABASE_URL`) and apply migrations themselves.

## Reading prescriptions
Without `GEMINI_API_KEY` the demo reader is used: it fills the review screen for the fake files in `../samples/` and nothing else. With a key, uploads are read by Gemini. On the free tier, upload fake prescriptions only. See `docs/02-architecture/adr/0003-extraction-and-chat.md`.

## API description
`npm run build && npm run openapi -- ../docs/02-architecture/openapi.json` rewrites the OpenAPI file (needs the environment variables set).

## Layout
| Folder | Stories |
|---|---|
| `auth`, `me` | sign-in, first-run acknowledgement (S8), profile (S10) |
| `documents`, `extraction` | upload and reading (S1, S2) |
| `prescriptions` | confirm, timeline (S2, S3) |
| `medicines`, `allergies` | feedback, course edit and stop, allergies (S4, S6) |
| `doses` | Today, taken and skipped, schedules for reminders (S6) |
| `notes`, `own-reminders` | free-text notes; own medicines with reminders (S7) |
| `chat`, `medicine-info` | recall and lookup rules; saved general medicine descriptions (S5, S8) |
| `doctors` | contact cards (S9) |
