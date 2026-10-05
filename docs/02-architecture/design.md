# UI design

Figma file: https://www.figma.com/design/HuVlA9b5rdyosFw0LVO2sR (DoseBook). Created 2026-10-04. The file's title in Figma still shows the old working name; it has to be renamed by hand in Figma (the API does not allow it).

Material 3, light scheme from the indigo seed already used in `mobile/lib/main.dart`. Roboto. Mobile frames 412 x 917. Fake data only.

## Pages
The Figma starter plan allows three pages per file, so the file has exactly three.

| Page | Content |
|---|---|
| Foundations | Colour, spacing and radius variables, text styles, specimen |
| Components | Icons and the components listed below |
| Screens | 19 frames, laid out in rows by journey |

## Screens and stories
| Frame | Journey | Stories |
|---|---|---|
| 01 First run | J0 | S8 |
| 02 Sign in | J0 | S1 (auth) |
| 03 Timeline | J1 | S3 |
| 04 Timeline, empty | J1 | S3 |
| 05 Upload | J1 | S1 |
| 06 Review extraction | J1 | S2, S8 |
| 07 Confirm schedule | J1 | S2, S6 |
| 08 Extraction failed | J1 | S2 |
| 09 Today | J4 | S6, S7 |
| 10 Chat, recall | J2 | S5, S8 |
| 11 Chat, escalation | J2 | S5, S8 |
| 12 Notes | J5 | S7 |
| 13 Add note | J5 | S7 |
| 14 Allergies and feedback | J3 | S4 |
| 15 Prescription, medicines | J6 | S9, S3 |
| 16 Prescription, doctor | J6 | S9 |
| 17 Doctors | J6 | S9 |
| 18 Doctor card | J6 | S9 |
| 19 Share doctor card | J6 | S9 |

Frames 06 and 08 also carry the doctor's phone, registration number, specialty and availability fields (S2, S9). The top bar action on 03 Timeline opens Doctors.

## Components
Button (filled, tonal, text; enabled, disabled), Chip (selected or not), Source tag (From prescription, Self-added), Text field (empty, filled, error), Doctor-vs-app banner, FAB, Top app bar, Bottom nav (Today, Timeline, Chat, Notes), Medicine card (by source, optional feedback chips), Timeline entry, Dose row (due, taken, skipped), Chat bubble (user, assistant), Escalation card, Empty state, List row, Tabs (Medicines, Doctor), Detail row (swappable icon, label, value), Doctor card.

Rules the components carry:
- Doctor details carry the line "As printed on your prescription. Not verified by the app."
- The share sheet previews exactly what is sent: the doctor's contact only, never the user's medicines or conditions.
- Every medicine shows a source tag. Self-added entries are never shown as prescribed.
- The Escalation card holds the fixed wording from `docs/01-requirements/what-we-do-and-dont.md` and has no editable text. It is never shown with a medicine list.
- The assistant chat bubble always ends with a doctor-vs-app line.
- A dose row from a self-added entry is labelled "Your reminder", not "As prescribed".

## Tokens to Flutter
Figma colour variables use the Flutter `ColorScheme` role names, so each maps directly to `Theme.of(context).colorScheme.<name>`.

| Figma variable | Value (light) |
|---|---|
| primary / onPrimary | #4355B9 / #FFFFFF |
| primaryContainer / onPrimaryContainer | #DEE0FF / #00105C |
| secondaryContainer / onSecondaryContainer | #E0E1F9 / #181A2C |
| tertiaryContainer / onTertiaryContainer | #FFD7F1 / #2D1228 |
| surface / onSurface / onSurfaceVariant | #FBF8FF / #1B1B1F / #46464F |
| surfaceContainerLow / surfaceContainer / surfaceContainerHigh | #F5F2FA / #EFEDF4 / #E9E7EF |
| outline / outlineVariant | #777680 / #C7C5D0 |
| error / errorContainer / onErrorContainer | #BA1A1A / #FFDAD6 / #410002 |

The hex values are a hand-entered approximation of the indigo-seed scheme. In code, keep `ColorScheme.fromSeed` as the source of truth; do not copy these hex values into the app.

Spacing: 4, 8, 12, 16, 24, 32. Radius: 8, 12, 16, 28, full. Text styles follow the Material 3 type scale names (`headline-small`, `title-large`, `title-medium`, `body-large`, `body-medium`, `label-large`, `label-medium`), which map to `TextTheme.headlineSmall` and so on.

## Built in the app without a Figma frame
The Figma plan's call limit was reached before these could be drawn. They follow the same components.
- "Same doctor?" dialog in the confirm step
- Edit doctor (also where a missing number is added) and its delete confirmation
- A doctor's prescriptions list
- Edit schedule and "Stop reminders" for a course, on the prescription screen
- My profile (S10), with the allergies list
- Notes as free text, and "My reminder" add/edit from Today (S7). These replace Figma frames 12 and 13
- Feedback on past medicines (replaces frame 14 together with the profile); feedback chips on the prescription
- Chat without feedback chips, with the medicine lookup card and the decline message (frames 10 and 11 are partly out of date)
- Password show/hide on sign-in
- Splash, the visitor view of each tab, and a separate Create account screen (S11). A script that draws these three frames and the logo sheet is saved in `docs/02-architecture/assets/figma-s11-frames.js`; the plan's call limit refused it on 5 Oct 2026. Run it once with `use_figma` when the limit resets, then move these lines into the frame table as 20 to 22.

## Logo
An open book with a capsule above the fold: the user's own book of doses. White on the primary colour; the right half of the capsule is primaryContainer.

- Source drawing: `docs/02-architecture/assets/dosebook-logo.svg` (108 x 108 grid; the mark sits inside the centre two thirds, the part an Android adaptive icon never crops).
- In the app: `mobile/lib/widgets/logo.dart` (`AppLogo`, drawn in code from the theme colours, no image file).
- Android launcher icon and launch screen: `mobile/android/app/src/main/res/drawable/ic_logo_foreground.xml`, `mipmap-anydpi-v26/ic_launcher.xml`, `drawable/launch_background.xml`, `values-v31/styles.xml`. The PNG icons in `mipmap-*` (for Android 7) were rendered from the SVG.
- The same three files must change together if the logo changes.
- Colour: the launch screen uses #515B92, the primary colour Flutter derives from the indigo seed (read from the running theme), so the Android launch screen and the Flutter splash match. The #4355B9 in the table above is the older hand-entered approximation used in the Figma file.
- Not in Figma yet (see above). iOS icon not made.

## Not designed yet
- Dark theme
- Web (wide) layouts for the judge demo link
- Notification appearance, loading skeletons, password reset
