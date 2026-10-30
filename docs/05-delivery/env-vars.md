# Environment variables (names only)

Values never go in the repo. See `backend/.env.example`.

## Backend
| Name | Required | Purpose |
|---|---|---|
| `DATABASE_URL` | yes | PostgreSQL connection string |
| `JWT_SECRET` | yes | Signs session tokens. Long random value, different per environment |
| `JWT_EXPIRES_IN` | no | Token lifetime, default `7d` |
| `PORT` | no | Default `3000` |
| `FILE_STORAGE` | no | `disk` (default) or `database`. Use `database` on a host whose disk does not last (ADR 0005) |
| `UPLOAD_DIR` | no | Where uploaded files are stored when `FILE_STORAGE=disk`, default `./uploads` |
| `TRUST_PROXY` | no | `true` behind a hosting proxy, so rate limits count per visitor. Leave unset otherwise |
| `THROTTLE_LIMIT` | no | Requests per minute per client, default 120 |
| `AUTH_THROTTLE_LIMIT` | no | Sign-in requests per minute per client, default 10 |
| `CHAT_THROTTLE_LIMIT` | no | Chat requests per minute per client, default 30 |
| `UPLOAD_THROTTLE_LIMIT` | no | Uploads per minute per client, default 20 |
| `GEMINI_API_KEY` | no | Turns on reading prescriptions with Gemini (free tier: fake prescriptions only) and the one-time fetch of a general description for a looked-up medicine |
| `GEMINI_MODEL` | no | Default `gemini-flash-latest`, Google's alias for its current Flash model. The demo server sets `gemini-flash-lite-latest`: on 30 Oct 2026 a new key could not use the 2.5 models and the Flash alias did not answer, while Flash-Lite answered in 2 to 7 seconds |
| `GEMINI_FALLBACK_MODEL` | no | Default `gemini-flash-lite-latest`. Used when the first model is retired, over its free quota, overloaded, or does not answer within 10 seconds |
| `TEST_DATABASE_URL` | no | Database for end-to-end tests. Defaults to the local one from `scripts/dev-db.sh` |

## Mobile
| Name | How it is passed | Purpose |
|---|---|---|
| `API_BASE_URL` | `--dart-define=API_BASE_URL=...` | Backend address. Default `http://10.0.2.2:3000`, which is the host machine as seen from the Android emulator |
| `DEMO` | `--dart-define=DEMO=true` | The build for judges: shows the samples-only note on upload and the waking-server hint |

In the pipeline, `API_BASE_URL` is a CI/CD variable; the `demo-apk` job runs only when it is set.

The app holds no keys.
