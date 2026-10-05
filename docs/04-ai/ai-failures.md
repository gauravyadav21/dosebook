
| 2026-10-06 | Claude Code | After adding a table, six tests failed with a Prisma validation error and the build broke | Assumed `prisma migrate dev` regenerates the client; with this set-up it did not | Ran `npx prisma generate`. Added to the runbook: generate after every schema change |
