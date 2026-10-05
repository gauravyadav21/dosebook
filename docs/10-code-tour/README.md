# Code tour

A guided walk through the code, one user action at a time. Each tour follows a single action through every file it touches, says what each step does and why it is there, and names the test that proves it. Read with the files open beside you. Written 5 Oct 2026 against the code as it was that day; references use file and function names, not line numbers.

## Order to read
1. This page (the map).
2. [01 Sign-in and the token](01-sign-in-and-token.md)
3. [06 How data stays private](06-how-data-stays-private.md) (short; builds on 01)
4. [02 Upload to confirm](02-upload-to-confirm.md) (the core journey)
5. [03 Doses and reminders](03-doses-and-reminders.md)
6. [04 A chat message](04-chat-message.md)
7. [05 How a screen refreshes](05-how-a-screen-refreshes.md)
8. [07 How the tests work](07-how-the-tests-work.md)

Each tour ends with things to try and questions with answers. Doing those is the point; reading alone will not stick.

## The two halves
| | Backend | App |
|---|---|---|
| Folder | `backend/` | `mobile/` |
| Language | TypeScript | Dart |
| Framework | NestJS | Flutter |
| Job | Owns the data and every rule. Trusts nothing the app sends | Shows screens and sends requests. Holds no rules that matter for safety |
| Talks to | PostgreSQL through Prisma; Gemini over HTTP | The backend over HTTP |

The app can be wrong or replaced and the data stays safe, because every check is repeated on the server. That is why validation and the "is this your record?" check live in the backend.

## How one request travels
Take "show my timeline":

1. A screen (`mobile/lib/features/timeline/timeline_screen.dart`) asks `Loader` to load data.
2. `Loader` calls a method on `Api` (`mobile/lib/api/api.dart`), here `prescriptions()`.
3. `Api._send` builds the HTTP request and adds the token.
4. On the server, `AuthGuard` (`backend/src/auth/auth.guard.ts`) checks the token and notes who is asking.
5. The controller (`backend/src/prescriptions/prescriptions.controller.ts`) receives the request. If there is a body, the validation pipe checks it against a DTO class first.
6. The service (`prescriptions.service.ts`) asks the database through Prisma, always filtered by the user's id.
7. A view function (`prescriptions.views.ts`) shapes the rows into the JSON the app receives.
8. Back in the app, `Api` turns the JSON into Dart objects (`mobile/lib/api/models.dart`), and the screen draws them.

Every feature follows this path. Once you can trace one, you can trace all of them.

## Backend layout (`backend/src/`)
| Folder | What is in it |
|---|---|
| `main.ts`, `app.module.ts`, `configure-app.ts` | Start-up: which modules exist, the two global guards, the validation pipe, Swagger |
| `common/` | Configuration from the environment, date helpers, slot names, the shared Gemini call |
| `prisma/` | The database connection |
| `auth/`, `me/` | Accounts, the token, the guard; acknowledgement and profile |
| `documents/`, `extraction/` | Upload, file-type check, reading a prescription |
| `prescriptions/` | Confirm, timeline, the JSON shapes |
| `medicines/`, `allergies/` | Feedback, course edit and stop, allergies |
| `doses/` | Today, marking doses, schedules for reminders |
| `notes/`, `own-reminders/` | Free-text notes; the user's own reminders |
| `chat/`, `medicine-info/` | Chat rules; saved medicine descriptions |
| `doctors/` | Doctor cards, matching, share text |
| `generated/` | The Prisma client. Generated; never edit; not in git |

Also: `backend/prisma/schema.prisma` (the tables), `backend/prisma/migrations/` (how the tables changed), `backend/test/` (end-to-end tests).

## App layout (`mobile/lib/`)
| Folder | What is in it |
|---|---|
| `main.dart` | Start-up, and `_Root`, which picks the splash, first run or the app (the app opens without sign-in; see tour 1) |
| `api/` | `api.dart` (every server call) and `models.dart` (the data classes) |
| `app/` | `app_scope.dart` (the session), `theme.dart` (light and dark theme, brand colours), `wording.dart` (fixed sentences), `format.dart` (dates, labels), `platform.dart` (file picker, dialler, share) |
| `features/<area>/` | One folder per area; each file is one or two screens |
| `reminders/` | `reminder_plan.dart` (pure planning) and `reminders.dart` (the notification plugin) |
| `widgets/` | `logo.dart` (the logo, drawn in code), `common.dart` (`Loader`, banners, empty state) and `cards.dart` (medicine, dose, doctor, timeline cards) |

## Words used in the code
| Word | Meaning |
|---|---|
| Module (NestJS) | A group of related controllers and services, registered in `app.module.ts` |
| Controller | A class whose methods answer HTTP routes (`@Get`, `@Post`…) |
| Service | A class holding logic a controller calls |
| DTO | A class describing a request body, with validation rules as decorators (`@IsString()`, `@Max(4)`) |
| Guard | Code that runs before a controller and can refuse the request |
| Pipe | Code that checks or converts input; here, the validation pipe |
| Prisma | The library that turns `schema.prisma` into typed database calls |
| Migration | A saved SQL step that changes the tables. Applied once, never edited |
| Widget (Flutter) | Anything on screen. `StatelessWidget` has no memory; `StatefulWidget` keeps state |
| `setState` | Tells Flutter "my data changed, redraw me" |
| `InheritedWidget` / `AppScope` | A way for any screen to reach the session without passing it down by hand |
| `ChangeNotifier` | An object that tells listeners when it changed. `Session` is one |
| Unit / end-to-end / widget test | Tests one function / the whole server through HTTP / one screen with a fake server |

## What to keep in mind while reading
Many choices in this code were made by the AI agent without being asked (marked "agent default" in `docs/08-build-log/decisions.md`). Each tour points out the main ones. Question them.
