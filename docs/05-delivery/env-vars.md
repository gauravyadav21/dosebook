# Environment variables (names only)

Values never go in the repo. See `backend/.env.example`.

## Backend
| Name | Required | Purpose |
|---|---|---|
| `DATABASE_URL` | yes | PostgreSQL connection string |
| `JWT_SECRET` | yes | Signs session tokens. Long random value, different per environment |
| `JWT_EXPIRES_IN` | no | Token lifetime, default `7d` |
| `PORT` | no | Default `3000` |
| `UPLOAD_DIR` | no | Where uploaded files are stored, default `./uploads` |
| `THROTTLE_LIMIT` | no | Requests per minute per client, default 120 |
| `AUTH_THROTTLE_LIMIT` | no | Sign-in requests per minute per client, default 10 |
| `CHAT_THROTTLE_LIMIT` | no | Chat requests per minute per client, default 30 |
| `GEMINI_API_KEY` | no | Turns on reading prescriptions with Gemini (free tier: fake prescriptions only) and the one-time fetch of a general description for a looked-up medicine |
| `GEMINI_MODEL` | no | Default `gemini-flash-latest`, Google's alias for its current Flash model |
| `GEMINI_FALLBACK_MODEL` | no | Default `gemini-flash-lite-latest`. Used when the first model is retired, over its free quota or overloaded |
| `TEST_DATABASE_URL` | no | Database for end-to-end tests. Defaults to the local one from `scripts/dev-db.sh` |

## Mobile
| Name | How it is passed | Purpose |
|---|---|---|
| `API_BASE_URL` | `--dart-define=API_BASE_URL=...` | Backend address. Default `http://10.0.2.2:3000`, which is the host machine as seen from the Android emulator |

The app holds no keys.
