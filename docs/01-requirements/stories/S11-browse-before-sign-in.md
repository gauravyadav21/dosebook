# S11: Browse before sign-in, sign-up, splash
As a new visitor I can open the app and see what it does before I create an account, and I am asked to sign in only when I do something that needs to know who I am.

Requested by the participant on 5 Oct 2026 after using the app.

Acceptance criteria
- Given the app is starting, a splash screen shows the DoseBook logo, the name and the line "We recall, we remind, we never prescribe."
- Given nobody is signed in, the app opens on the Today tab, not on a sign-in screen. All four tabs (Today, Timeline, Chat, Notes) can be opened.
- Given nobody is signed in, each tab explains in a few lines what it does and offers "Sign in" and "Create account". It shows no data and no examples, and sends no request to the server.
- Given nobody is signed in, when the visitor taps an action that saves or loads personal data (My reminder, Upload, New note, Doctors), the sign-in screen opens. After a successful sign-in the action the visitor asked for continues.
- Given nobody is signed in, when the visitor sends a chat message (a symptom or a medicine name), the sign-in screen opens and the typed message is kept. Medicine lookup always needs sign-in.
- The account menu shows "Sign in" and "Create account" to a visitor, and the email, profile, feedback and "Sign out" to a signed-in user.
- Sign-in and sign-up are two separate screens that link to each other. Both can be left with the back button without signing in.
- Sign-up asks for email, password and the password again. The password can be shown or hidden.
- Given a new account, the first-run acknowledgement (S8) is shown before anything else; the app cannot be used before it is accepted.
- Given the user signs out, the app returns to the visitor tabs.
- Given a session expires, the app returns to the visitor tabs, says the session ended, and phone reminders are cleared.
- Negative: email without "@", password under 8 characters, or passwords that do not match -> message on the field, no request sent.
- Negative: wrong password, or an email already registered -> the server's message is shown and the visitor stays on the screen.
- Negative: server unreachable during sign-in or sign-up -> message shown, nothing changes.

API changes
- None. Every route except `/auth/register`, `/auth/login` and `/health` already needs a token; the visitor screens call none of them.

Data model changes
- None.

Future scope (not built)
- Verify the email address entered at sign-up (send a link or a code) before the account is used.

Design: built in the app first. The Figma frames and logo sheet are a saved script not yet run (call limit); see the Logo section of `docs/02-architecture/design.md`.
