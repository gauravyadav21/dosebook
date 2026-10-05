# Deployment: the demo server and the judges' APK

Decision and trade-offs: `docs/02-architecture/adr/0005-demo-hosting.md`. Story: S13.

**State on 6 Oct 2026: prepared and tested locally, not yet deployed.** The accounts and secrets below are the participant's to create. The AI agent never sees them.

## What runs where
| Part | Where | From |
|---|---|---|
| Backend | Render, free web service `dosebook-api` | `backend/Dockerfile`, described in `render.yaml` |
| Database | Neon, free PostgreSQL | migrations in `backend/prisma/migrations`, applied at each start |
| Uploaded files | The same database, table `DocumentBlob` | `FILE_STORAGE=database` |
| App for judges | Release APK, artifact of the `demo-apk` pipeline job on `main` | `.gitlab-ci.yml` |

## Free-plan limits, as read on 6 Oct 2026 (check again before relying on them)
- Render (render.com/docs/free): 750 free instance hours a month per workspace; a free web service stops after 15 minutes without traffic and takes about one minute to start again; its filesystem is wiped on every redeploy, restart or stop. The page read did not state RAM, CPU, or whether a card is needed; check at sign-up, and stop if a card is asked for.
- Neon (neon.com/pricing): free plan is permanent, no card; 1 GB storage per project; 100 compute-hours per project a month; compute pauses after 5 idle minutes.

## Steps (participant)
1. **Neon.** Create a project (any region near you). Copy the connection string. It must end with `?sslmode=require`. Use the direct string, not the pooled one, so migrations work.
2. **A new signing secret.** In Terminal: `openssl rand -hex 32`. Do not reuse the one in `backend/.env`.
3. **Render.** New → Blueprint → connect the GitLab repository → it reads `render.yaml`. Enter the three values it asks for: `DATABASE_URL` (from step 1), `JWT_SECRET` (from step 2), `GEMINI_API_KEY` (your free key). Apply.
4. **Check.** When the deploy finishes, open `https://<your-service>.onrender.com/health`. It should show `{"status":"ok"}`. The first lines of the deploy log should show the migrations being applied.
5. **Tell the pipeline the address.** GitLab → Settings → CI/CD → Variables → add `API_BASE_URL` = `https://<your-service>.onrender.com` (not masked, not protected; it is an address). Run the pipeline on `main`.
6. **Get the APK.** Pipeline → job `demo-apk` → Download artifacts → `dosebook-demo.apk`.
7. **Give judges access.** The project is private, so the artifact needs sign-in. Either make the project public at submission, or attach the APK to a GitLab Release. Also give them the three files in `samples/`.

None of these values go into a chat, a file in the repo, or `render.yaml`.

## What the settings do
See `render.yaml` and `docs/05-delivery/env-vars.md`. In short: files in the database, one trusted proxy hop, and per-visitor limits of 60 requests, 5 sign-in attempts, 10 chat messages and 4 uploads a minute.

## After it is up: checks to run
```
BASE=https://<your-service>.onrender.com
curl -s $BASE/health
curl -s -o /dev/null -w "%{http_code}\n" $BASE/prescriptions          # 401: no token
```
Then in the app: create an account with a made-up address, upload a sample, confirm, close the app, redeploy from Render's dashboard, open the prescription and "View original document". It must still be there.

## Everyday
- **Redeploy:** push to `main`; Render rebuilds by itself. Or "Manual Deploy" in the dashboard.
- **Roll back:** Render dashboard → Events → pick an earlier deploy → Rollback. Migrations are not undone; do not roll back across a migration without thinking.
- **First request is slow:** the service was asleep. Wait a minute and try again.
- **Reading stopped working:** the model's free quota is used up, or the key is wrong. Upload still works with manual entry. Check the service log for `Extraction failed`.
- **Wipe the demo data:** in Neon's SQL editor, `truncate "User" cascade;`. Everything a user owns goes with them.
- **Change a secret:** Render dashboard → Environment. Changing `JWT_SECRET` signs everyone out.
- **A newer APK will not install over an older one:** each pipeline run signs with a fresh debug key. Uninstall the old app first.

## Not set up
Backups, monitoring, alerts, a custom domain, a staging copy, a kept signing key.
