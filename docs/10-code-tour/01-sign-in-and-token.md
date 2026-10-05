# Tour 1: sign-in and the token

Since S11 (5 Oct 2026) the app does not start on sign-in. It opens on the tabs as a visitor, and the sign-in screen is pushed on top when the visitor asks for it or starts something that needs an account. "Before sign-in" below explains that part.

Follows: you type an email and password and press Sign in. Then: how every later request proves who you are.

## Before sign-in: the visitor
- **`mobile/lib/main.dart`, `_Root`.** While the saved session is being restored it shows `SplashScreen`. After that it shows `HomeShell` whether or not anyone is signed in.
- **Each tab** (`today_screen.dart`, `timeline_screen.dart`, `notes_screen.dart`) checks `session.signedIn` before it builds its `Loader`. A visitor gets `GuestView` instead: an explanation and two buttons. Because the `Loader` is never built, no request is sent.
- **`mobile/lib/features/auth/require_sign_in.dart`, `requireSignIn`.** The one gate. Every action that saves or loads the user's own data calls it first: `if (!await requireSignIn(context) || !context.mounted) return;`. Signed in: it returns true at once. Visitor: it pushes `SignInScreen`, waits for it to close, and returns `session.canUse`.
- **`Session.canUse`** (`app_scope.dart`) is true only when there is a token, the profile has loaded and the first-run acknowledgement is done. That is why a brand-new user who taps Upload, signs up, and lands on the acknowledgement is not then thrown into the upload screen.
- **Chat** (`chat_screen.dart`, `_send`) calls the same gate before sending, and does not clear the text box until after it, so the question survives the trip to sign-in.
- **Sign-up** is its own screen, `sign_up_screen.dart`: email, password, password again. It calls the same `Session.signIn` with `register: true`.

## The path
### In the app
1. **`mobile/lib/features/auth/sign_in_screen.dart`, `_submit`.** Checks the form first (an email with `@`, a password of 8 or more characters), so an obviously bad input never reaches the server. Then calls `Session.signIn`. If that throws, the message is shown under the fields. If it succeeds the screen closes itself with `Navigator.pop(true)`, which is what lets `requireSignIn` continue.
2. **`mobile/lib/app/app_scope.dart`, `Session.signIn`.** Four things in order: call `api.login` (or `api.register`), keep the returned token in `api.token`, save it to the phone's preferences under `session_token`, then call `api.me()` to learn who you are and whether the first-run acknowledgement is needed. Last, `notifyListeners()`.
3. **`mobile/lib/api/api.dart`, `login`.** Sends `POST /auth/login` through `_send`. Note `changes: false`: signing in is not a change to your data, so open screens are not told to reload.

### On the server
4. **`backend/src/auth/auth.controller.ts`.** The class is marked `@Public()`, so the guard lets it through without a token. It is also marked `@Throttle` with a lower limit than the rest of the API, to slow down password guessing. The body is checked against `CredentialsDto` (`auth.dto.ts`), which also lower-cases the email.
5. **`backend/src/auth/auth.service.ts`, `login`.** Looks the user up by email, then calls `verifyPassword`. Unknown email and wrong password give the same error on purpose, so nobody can find out which emails have accounts.
6. **`backend/src/auth/password.ts`.** `hashPassword` makes a random salt and runs scrypt; what is stored is `scrypt$<salt>$<hash>`, never the password. `verifyPassword` repeats the hash with the stored salt and compares with `timingSafeEqual`, which takes the same time whether the first or last character differs.
7. **`auth.service.ts`, `issue`.** Signs a token (a JWT) containing only the user's id, valid for 7 days by default. The secret used to sign it comes from `JWT_SECRET` in `backend/.env`.

### Back in the app
8. **`mobile/lib/main.dart`, `_Root`.** Rebuilds because the session notified. It now sees a token and a `me`. If the acknowledgement is required it shows `FirstRunScreen`; otherwise `HomeShell`, whose tabs now build their `Loader` and fetch. `HomeShell` also notices the change from visitor to signed in and syncs the phone's reminders.

## Every request after that
- **`api.dart`, `_headers`** adds `authorization: Bearer <token>` to each request.
- **`backend/src/app.module.ts`** registers two global guards: the rate limiter, then `AuthGuard`. Global means they run for every route.
- **`backend/src/auth/auth.guard.ts`, `canActivate`**:
  1. If the route is marked `@Public()`, allow.
  2. No `Bearer` token: 401.
  3. Verify the token's signature and expiry: failure is 401.
  4. Check the user still exists in the database: a token for a deleted account is 401.
  5. Put the user's id on the request.
- **`backend/src/auth/auth.decorators.ts`, `@UserId()`** hands that id to the controller method. Controllers never read a user id from the request body; it only ever comes from the verified token.

## Signing out and expiry
- **`Session.signOut`** clears the token, removes it from preferences, clears pending reminders (another person's reminders must not fire on this phone) and notifies, so the tabs go back to the visitor view. `ChatScreen` drops its answers at the same moment, so one person's answers are not left on screen for the next.
- **`api.dart`, `_read`**: a 401 on any request while a token is set calls `onUnauthorized`, which is `Session.signOut`. It calls `signOut(expired: true)`, which also sets `sessionEnded`, so the visitor view says "Your session ended. Sign in again."
- **`Session.restore`** runs at start-up. It keeps the token if the server is merely unreachable and drops it only if the server refused it.

## Tests that prove it
- `backend/test/auth.e2e-spec.ts`: "stores the password hashed, never in plain text", "gives the same answer for an unknown email as for a wrong password", "refuses an expired token", "refuses a token whose account no longer exists".
- `backend/test/throttle.e2e-spec.ts`: "blocks repeated login attempts past the limit".
- `mobile/test/widget_test.dart`: "signs in, shows the acknowledgement once, then opens Today", "opens on Today as a visitor, explains every tab and sends no request", "asks a visitor to sign in before Upload, then continues to the upload screen", "does not continue to Upload for a new user until the acknowledgement is accepted", "asks a visitor to sign in before chat sends, keeps the message, then sends it", "returns to the visitor tabs, says the session ended and clears reminders when it expires".

## Agent defaults to question
- The token lives in app preferences, not the phone's secure keystore.
- No refresh token, password reset or email check.
- A token stays valid for 7 days and cannot be cancelled early from the server.

## Things to try
1. In `auth.dto.ts`, change the minimum password length from 8 to 12. Run `npm run test:e2e`. Which tests fail, and why?
2. In `auth.guard.ts`, comment out the "user still exists" check. Run the auth tests. One fails; read its name.
3. Sign in on the emulator, then open Prisma Studio and look at your row in `User`. Find the salt and the hash in `passwordHash`.

## Check your understanding
1. Where does a controller get the user's id from?
2. Why does `login` not tell you whether the email exists?
3. What happens in the app when the server answers 401 to a normal request?
4. Why is `changes: false` passed for login?

Answers: (1) From the verified token, via `AuthGuard` and `@UserId()`; never from the request body. (2) So accounts cannot be discovered by trying emails. (3) `_read` calls `onUnauthorized`, `Session.signOut` runs, `_Root` shows sign-in. (4) So `Session.revision` does not change and open screens do not reload for something that changed no data.
