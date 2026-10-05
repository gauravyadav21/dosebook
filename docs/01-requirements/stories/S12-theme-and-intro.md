# S12: Light and dark mode, and intro screens
As a visitor I am shown in a few pages what the app does and does not do before I use it, and as any user I can use the app in light or dark mode.

Requested by the participant on 5 Oct 2026.

Acceptance criteria: appearance
- Given no choice has been made, the app follows the phone: dark when the phone is in dark mode, light otherwise.
- The account menu has "Appearance" for visitors and signed-in users, with three choices: System, Light, Dark. The current choice is marked.
- Given a choice is made, the whole app changes at once, and the choice is kept on the phone across restarts and across sign-out.
- The choice belongs to the phone, not the account, and is not sent to the server.
- The splash and the logo keep the brand colour in both modes, so the start of the app looks the same as the Android launch screen.
- Every screen stays readable in dark mode: colours come from the theme, none are fixed in a screen.

Acceptance criteria: intro
- Given nobody is signed in, when the app starts, four intro pages are shown after the splash and before the tabs. This happens on every start until the user signs in.
- The pages, in order: (1) your prescriptions in one timeline, (2) dose reminders as written on your prescription, (3) what worked for you and medicine lookup, (4) what DoseBook never does: diagnose, prescribe or suggest new medicines, change a dose or replace your doctor.
- Page 4 uses the same fixed wording as the first-run acknowledgement (S8), not a paraphrase.
- Pages can be swiped. "Next" moves on, "Skip" and, on the last page, "Get started" go to the visitor tabs. "Sign in" on any page opens the sign-in screen.
- The intro shows no personal data and sends no request.
- Given a signed-in user, the intro is not shown at start. It is not shown again after Sign out within the same run of the app.
- The account menu has "About DoseBook", which opens the same pages at any time; there, closing returns to where the user was.
- The intro does not replace the first-run acknowledgement: a new account still has to accept it before using the app.

API changes
- None.

Data model changes
- None. The appearance choice is stored on the phone under `theme_mode`.

Open points decided by the AI agent, for review
- Whether the intro has been dismissed is kept in memory only, so "every start until sign-in" holds without storing anything.
- No dark-mode frames are drawn in Figma.
