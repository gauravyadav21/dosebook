# Tour 6: how data stays private

A short tour of the rules that stop one user seeing another's data, and stop bad input getting in. Read Tour 1 first.

## Rule 1: every route needs a token unless marked otherwise
**`backend/src/app.module.ts`** registers `AuthGuard` as a global guard. The default is "locked". A route is open only if it or its class carries `@Public()` (`backend/src/auth/auth.decorators.ts`). Today that is register, login and health. A new route added tomorrow is protected without anyone remembering to protect it.

## Rule 2: the user id comes only from the token
Controllers take the id with `@UserId()`. No DTO has a `userId` field, so a request cannot say "I am someone else".

## Rule 3: every query is filtered by that id
Look at any controller. For example **`backend/src/doctors/doctors.controller.ts`, `find`**:
```ts
const doctor = await this.prisma.doctor.findFirst({ where: { id, userId } });
if (!doctor) throw new NotFoundException('Doctor not found');
```
The record is looked up by its id **and** your id together. Someone else's doctor is simply not found.

## Rule 4: another user's record is 404, not 403
403 would say "this exists, but it is not yours", which confirms that the id is real. 404 says the same thing for "not yours" and "does not exist", so ids cannot be probed.

## Rule 5: input is checked against a class, and unknown fields are refused
**`backend/src/configure-app.ts`** sets one validation pipe for the whole app:
- `whitelist` and `forbidNonWhitelisted`: a field that is not declared in the DTO makes the request fail with 400. A request cannot smuggle in `role: "admin"`.
- `transform`: values are converted to the declared types.

Each DTO states its limits as decorators. See **`backend/src/prescriptions/prescriptions.dto.ts`** (lengths, phone pattern, nested objects), **`backend/src/prescriptions/schedule.dto.ts`** (slots, 1-365 days) and **`backend/src/me/profile.dto.ts`** (height and weight ranges, blood groups).

Route parameters that should be ids use `ParseUUIDPipe`, so `/documents/not-a-uuid` is a 400 before any query runs.

## Rule 6: files
**`backend/src/documents/`**: the type is read from the file's bytes; the stored name is random; the download route (`file`) goes through the same owner check as everything else. There is no public folder of uploads.

## Rule 7: secrets and configuration
**`backend/src/common/config.ts`, `loadConfig`** reads everything from the environment and stops the server at start-up if `DATABASE_URL` or `JWT_SECRET` is missing. Values live in `backend/.env`, which is gitignored; `backend/.env.example` holds names only. The app (`mobile/`) holds no keys at all; its only setting is the backend address.

## Rule 8: rate limits
Three limits, all from the environment: the whole API, sign-in routes (lower), chat (lower, because a lookup can cost a model call).

## Rule 9: what leaves the server for a third party
Only two things, both in **`backend/src/common/gemini.ts`**: an uploaded prescription file (for reading), and a medicine name (for a description). The key travels in a header. Error messages carry the HTTP status only, so nothing from the request ends up in logs.

One table is shared by all users on purpose: `MedicineInfo`. It has no user id and holds only a medicine's name and general description.

## Tests that prove it
Every end-to-end file has an "another user" case. Examples:
- `backend/test/prescriptions.e2e-spec.ts`: "never shows another user's entries".
- `backend/test/doctors.e2e-spec.ts`: "cannot list, read, share, change or delete another user's doctors".
- `backend/test/profile.e2e-spec.ts`: "does not let the profile change the email or password".
- `backend/test/auth.e2e-spec.ts`: "requires a token on protected routes".
- `backend/test/documents.e2e-spec.ts`: "rejects an id that is not a UUID".

## What is not covered (agent defaults and gaps)
- Uploaded files are not encrypted on disk.
- The database has no row-level security; the filter is in the application code, so a query written without the filter would leak. The tests are the safety net.
- No audit log of who read what.
- No security review has been done yet (`security-check` skill).

## Things to try
1. In `doctors.controller.ts`, change `where: { id, userId }` to `where: { id }` in `find`. Run `npm run test:e2e`. Read the failing test's name. Put it back.
2. With the backend running, open `/docs`, authorise with a token, and send a `PUT /me/profile` with an extra field. Read the 400.
3. Search the backend for `findUnique(`. For each one, check how the user is limited. (Hint: most lookups use `findFirst` with `userId` for this reason.)

## Check your understanding
1. A new controller is added with no decorators. Is it open or protected?
2. Why 404 instead of 403 for someone else's record?
3. Where would a request's extra field `isAdmin: true` be stopped?
4. Which table has no `userId`, and why is that acceptable?

Answers: (1) Protected: the guard is global and the default is locked. (2) So the answer does not reveal that the id exists. (3) The validation pipe, because of `forbidNonWhitelisted`. (4) `MedicineInfo`: it holds general text about medicines and nothing about any user.
