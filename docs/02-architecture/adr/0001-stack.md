# ADR 0001: Stack

Status: accepted. Date: 2026-10-03.

- Mobile: Flutter, also built for web so judges can use a link.
- Backend: NestJS + Prisma + PostgreSQL; Swagger/OpenAPI generated, Dart client generated from it.
- Auth: Firebase Auth or JWT (decide in ADR 0002).
- Skipped on purpose: Redis, queues, anything not serving the core journey.

Trade-off: a single typed stack of well-known frameworks over novelty; fewer moving parts to deploy and demo.
