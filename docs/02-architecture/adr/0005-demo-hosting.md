# ADR 0005: Hosting for the demo, and files in the database

Status: accepted. Date: 2026-10-06.

## Context
Judges need to try the app, and deployment is scored. The budget is zero and no card is to be used. Free container hosts stop an idle service and wipe its disk on every restart, which would lose uploaded prescriptions kept on disk (ADR 0004).

## Decision
- **Backend on Render's free web service, built from `backend/Dockerfile`; database on Neon's free PostgreSQL.** The container applies migrations, then starts.
- **Judges get an Android APK** built by the pipeline, pointed at the hosted server. No web app: the product is a phone app with phone notifications, and a web build would need its own work.
- **On the demo, uploaded files are stored in PostgreSQL** in a separate table, `DocumentBlob`, chosen by `FILE_STORAGE=database`. Disk stays the default for development. One interface, `FileStore` (`backend/src/documents/file-store.ts`), with two implementations.
- **The server trusts exactly one proxy hop** (`TRUST_PROXY=true`) so rate limits count per visitor.
- **Live Gemini on the demo**, with a per-visitor upload limit, lower general limits, and a note on the upload screen to use the samples only.

## Why files in the database
- It survives restarts with nothing else to sign up for.
- It is atomic: the row and its bytes are written in one statement, so there is never a row without a file.
- Files are at most 10 MB and few. Neon's free plan allows 1 GB per project (read on 6 Oct 2026).
- The bytes are in their own table, so listing or reading documents never loads them.

## Trade-offs accepted
- **A database is the wrong place for files at scale.** It grows the database, makes backups heavy, and holds each file in memory while serving it. With real use this moves to object storage behind the same `FileStore` interface; nothing else changes.
- **The free host sleeps.** After 15 idle minutes the first request takes about a minute (Render's own figure, read on 6 Oct 2026). The app says so in the demo build. A paid instance removes it.
- **The APK is signed with a debug key** made fresh by each pipeline run, so a newer APK cannot be installed over an older one without uninstalling first. Enough for a side-loaded demo; a real release needs a kept signing key.
- **The model key is a free-tier key on a public server.** Quota can run out during judging; the app then falls back to typing the details in. Free tiers may train on what is sent, hence samples only.
- **Trusting a proxy header** is only safe behind a proxy that sets it. The setting is off by default.

## Not done
Backups, monitoring, alerts, a custom domain, a staging environment, secrets rotation.
