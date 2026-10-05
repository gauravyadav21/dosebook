# Runbook

How to start, stop, inspect and fix the project on the development Mac. Commands assume the repo root unless a `cd` is shown.

## Start everything
```
cd backend
nvm use 20                      # Prisma 7 needs Node 20.19 or newer; the default Node 18 fails
npm run db:start                # local PostgreSQL on port 54329
npm run build
set -a && . ./.env && set +a && node dist/main.js     # or: npm run start:dev
```
Check: http://localhost:3000/health shows `{"status":"ok"}`. API docs: http://localhost:3000/docs.

Emulator and app:
```
~/Library/Android/sdk/emulator/emulator -avd Pixel_3a_API_32 &
cd mobile && flutter run        # or: flutter build apk --debug, then adb -s <serial> install -r build/app/outputs/flutter-apk/app-debug.apk
```
The app talks to `http://10.0.2.2:3000`, which is the Mac as seen from the emulator.

**Check the device first.** `adb devices`, then `adb -s <serial> shell getprop ro.product.model`. Always pass `-s <serial>`. Another emulator on this Mac belongs to day-job work and must not be used. The serial does not identify the device: whichever emulator starts first gets `emulator-5554`. Check the name with `adb -s <serial> emu avd name`; it must say `Pixel_3a_API_32`. The Pixel emulator also has day-job apps installed, so touch only `com.dosebook.app` on it.

## Stop
```
pkill -f "node dist/main.js"
cd backend && npm run db:stop
adb -s <serial> emu kill
```

## Demo account and samples
- A local demo account exists in the development database: `demo.patient@example.com` / `demo-password-123`. It is fake and local; create another from the sign-in screen at any time.
- Fake prescriptions: `samples/*.png`. Copy to the emulator with `adb -s <serial> push samples/*.png /sdcard/Download/`.

## Database
| Setting | Value |
|---|---|
| Host | `localhost` |
| Port | `54329` |
| Database | `dosebook_app` (development), `dosebook_test` (tests) |
| User | `app` |
| Password | none |

- psql: `/Library/PostgreSQL/15/bin/psql -h localhost -p 54329 -U app -d dosebook_app`
- Prisma Studio: `cd backend && nvm use 20 && npx prisma studio`
- pgAdmin 4: Register → Server with the values above. The pre-made "PostgreSQL 15" entry is a different server on port 5432.
- Table and column names with capitals need double quotes: `select email from "User";`
- Schema change: edit `backend/prisma/schema.prisma`, then `npx prisma migrate dev --name <what>` and `npx prisma generate`. Never edit or delete an applied migration.
- `backend/scripts/dev-db.sh reset` deletes the whole local cluster.

## Gemini key
1. Create a key at https://aistudio.google.com/apikey (personal Google account, no billing).
2. Add `GEMINI_API_KEY=...` to `backend/.env`. Never paste it into a chat or commit it.
3. Restart the backend.
4. Models: `GEMINI_MODEL` (default `gemini-flash-latest`) and `GEMINI_FALLBACK_MODEL` (default `gemini-flash-lite-latest`).
5. Saved medicine descriptions are in the `MedicineInfo` table. Delete a row to make it fetch again.

To see which models a key can use:
```
set -a && . backend/.env && set +a
curl -s "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200" -H "x-goog-api-key: ${GEMINI_API_KEY}" | grep '"name"'
```

## Review by a second model
```
nvm use 20
node scripts/gemini-review.mjs            # all six batches
node scripts/gemini-review.mjs chat app   # only these
```
Reads the key from `backend/.env`; sends only files under `backend/src` and `mobile/lib`. Output: `docs/04-ai/reviews/`. If a batch says "Not reviewed", the models were over quota; run that batch again later.

## Emulator: choosing a file in the system picker by script
Taps on a file are ignored. Open Downloads from the side menu, move focus with the arrow keys (`adb shell input keyevent 19/20/21/22`), read which item is focused from a UI dump, then press Enter (`keyevent 66`).

## Checks
```
cd backend && npm run lint && npm run build && npm test && npm run test:e2e
cd mobile  && flutter analyze && flutter test && flutter build apk --debug
gitleaks dir backend/src mobile/lib docs
```

## Troubleshooting: errors met and their fixes
| Symptom | Cause | Fix |
|---|---|---|
| Prisma refuses to run, or odd syntax errors from Node | Node 18 is the default | `nvm use 20` |
| `Missing required environment variable JWT_SECRET` | `.env` not loaded, or missing the line | `set -a && . ./.env && set +a`; check `.env.example` |
| Prisma asks to reset the database | A migration file was changed or deleted after being applied | Do not reset blindly. Restore the file; add changes as a new migration |
| Confirm returns 500 on a missing nested object | `@ValidateNested()` without `@IsDefined()` | Add `@IsDefined()` |
| File picker call does not compile | `file_picker` v13 changed its API | Use `FilePicker.pickFile(...)` and `file.readAsBytes()`; read the installed package source first |
| Card buttons overflow on a phone | Buttons in a `Row` | Use `Wrap`; widget tests run at 412 px |
| A widget test cannot find an item that is in a list | It is built but outside the visible area | `find.text(..., skipOffstage: false)` or scroll to it |
| `scrollUntilVisible` fails with "Too many elements" | Text fields are scrollables too | Pass `scrollable: find.byType(Scrollable).first` |
| Timeline stale after confirm | Screen refreshed itself by hand at the wrong moment | All screens load through `Loader`; see the `add-screen` skill |
| Gemini returns 404 | Model retired for new keys | Use the `-latest` alias; list models with the command above |
| Gemini returns 503 or 429 | Model overloaded or over the free quota | The backend falls back to the second model; otherwise wait |
| A curl URL with `$VAR:something` breaks in zsh | zsh reads `:g` as a modifier | Write `${VAR}:something` |
| App will not start on an emulator ("error code 5") | Wrong emulator (kiosk-style device) | Use the Pixel emulator; pass `-s <serial>` |
| pgAdmin asks for a master password | pgAdmin's own password store | Set or reset it; not related to the database |
| `git push`: "could not read Username for 'https://gitlab.com'" | Run where no prompt can appear | Run it in Terminal.app |
| `git push`: "HTTP Basic: Access denied" | Account password used, or a token without write scope | Personal access token with `write_repository` as the password. Clear a bad saved one: `printf "protocol=https\nhost=gitlab.com\n\n" \| git credential-osxkeychain erase` |
| `git push`: "rejected (fetch first)" | The remote has a commit you do not have (GitLab's README) | `git fetch origin`, look at it, `git rebase origin/main`, push. No force |
| CI does not start on GitLab | Only `.github/workflows/ci.yml` exists | GitLab reads `.gitlab-ci.yml` |
| Figma tools missing | Server registered but not signed in | `/mcp` → figma → authenticate |
| Figma refuses calls | Starter plan tool-call limit | Wait for reset; batch work into few calls |
