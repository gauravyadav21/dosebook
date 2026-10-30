# UI and UX rules

Project-agnostic. Copy this file into any app project and point the agent context file (`AGENTS.md`, `CLAUDE.md`) at it. Examples use Flutter and Material 3 because that is where the rules were first applied; the rules themselves hold for any toolkit. The two guard tests (`contrast_test`, `grid_test`) are the part that makes the rules stick: a rule that no test checks drifts.

Read this before building or changing any screen. Tick the checklist at the end before calling a screen done.

## 1. Colour: 60-30-10

| Share | Role | What it is | Examples |
|---|---|---|---|
| 60% | Dominant | The page: a quiet neutral, slightly tinted | `surface`, page background |
| 30% | Secondary | Containers and surfaces that group content | cards, `surfaceContainer*`, `secondaryContainer` tiles, chips, tonal buttons, nav bar, input fills |
| 10% | Accent | Where the eye should go and what is active | `primary` for the main button, selected tab, focused field, progress; `tertiary` as a rare second accent |

- Primary means "do this" or "you are here". One filled primary button per section of a screen.
- Secondary colour groups and informs. Tertiary is a small warm accent for people and personal things; at most one tertiary element per screen.
- Error and status colours (success, due, warning) are semantic. They sit outside the ratio and always carry an icon and a label, never colour alone.
- No full-screen primary or tertiary backgrounds except splash and onboarding.
- No hex values or fixed colours in a screen. Every colour is a role from the theme (`Theme.of(context).colorScheme`, or a theme extension for status colours). Only the logo and splash may use the fixed brand scheme.
- Both light and dark mode are designed, not inverted. Look at each new screen in both.

## 2. Contrast: WCAG AA, AAA for what matters

| Content | Minimum ratio | Standard |
|---|---|---|
| Normal text | 4.5:1 | AA |
| Large text (24 px, or 18.66 px bold, and up) | 3:1 | AA |
| Icons, borders of fields, focus rings, chart marks | 3:1 | AA (non-text) |
| **Important text** | **7:1** | AAA |

Important text is anything where misreading is costly: names, times and amounts, warnings, errors, safety wording, and the label on a filled button.

- Checked by `contrast_test.dart`, which computes the ratio for every text and background pair the theme produces, in light and dark. Add a pair there when you add a role or a status colour.
- If a generated colour fails, fix the role once in the theme (`ensureContrast` lifts it over the line and keeps the hue). Never patch it inside a screen.
- Do not rely on opacity to dim text: the contrast is then lower than the role's. Use the variant role (`onSurfaceVariant`) instead.
- Test with the system text size at 130% and 200%: nothing may clip or overlap. Use flexible layouts, not fixed heights for text.

## 3. Layout: the 8-point grid

- Every margin, padding, gap and component size is a multiple of 8. A half step of 4 is allowed for a tight pair (an icon and its label, a title and its subtitle). No 10, 12, 14, 20, 28.
- Tokens: `Space.xs 4, sm 8, md 16, lg 24, xl 32, xxl 40, xxxl 48`. Radii: `Corner.sm 8, md 16, lg 24`. Gaps: `Gap.sm`, `Gap.md`. Screens use these and never write a raw number (`grid_test.dart` fails on one).

| Where | Value |
|---|---|
| Screen side margin (gutter) | 16 |
| Between sections of a screen | 24 |
| Between items in a list | 8 |
| Inside a card | 16 |
| Between a label and its field | 8 |
| Under a scroll list with a floating button | 96 |
| Smallest tap target | 48 x 48 |
| Icon | 24 (20 only inside a chip) |
| Avatar, icon tile | 40 or 48 |
| Card and field radius | 16 |

- Align every screen's content to the same left gutter. Titles, section headers, cards and fields share one left edge.
- On a tablet or in a browser, centre the content column and cap it at 600 wide.
- A tap target smaller than 48 gets padding, not a bigger icon.

## 4. Type

- Use the theme's type scale roles (`headlineSmall`, `titleMedium`, `bodyMedium`, `labelLarge`). No font size, family or weight in a screen.
- One idea, one level: a screen has one headline or title, section headers one step below, body text for the rest. Do not use more than three levels on a screen.
- Left-align text. Keep lines under about 70 characters on wide screens.
- Put the important fact first and in the heavier weight (the medicine name before the dose, the dose before the note).

## 5. Components: one of each

Build or reuse one shared widget for each of these and use it everywhere. A second variant needs a reason in the pull request.

- Card (one style, optional accent tile).
- Text field (filled, rounded, label above or floating, error text below in the error role).
- Buttons: filled (main), tonal (secondary), outlined or text (tertiary and cancel). Never two filled buttons side by side.
- Confirm dialog for every destructive action: says what will happen and what will not, the safe choice on the left.
- States, designed on every screen that loads data:
  - **Loading**: a spinner, or a skeleton for lists.
  - **Empty**: icon, one line saying why it is empty, one line saying what to do, and the button that does it.
  - **Error**: icon, a plain-language sentence (never a raw exception), and Try again.
  - **Offline**: the same as error, with wording that says the connection is the problem.
- Snackbar for the result of an action, never for something the user must read before going on.

## 6. Navigation

- At most five primary destinations in the bottom bar. Selected state uses a filled icon and a tinted indicator, so it does not depend on colour alone.
- Tabs keep their scroll position and state when you switch away and back.
- Profile and settings are reachable in one tap from every main screen, not hidden in an overflow menu.
- The title of a screen matches the label that led to it.
- Back always goes back. A screen reached from a notification still has a way up.

## 7. Motion and feedback

- Motion explains a change (a card appearing, a page sliding in), 150 to 300 ms, never decoration. Respect the system "reduce motion" setting.
- Every tap shows a response within 100 ms (ripple, pressed state, in-button progress). A long action shows progress and disables its button so it cannot be sent twice.
- Pull to refresh on every list that comes from a server.

## 8. Accessibility

- Every icon-only button has a tooltip or semantic label. Every image that carries meaning has a text alternative; decorative ones are excluded from the semantics tree.
- Order of focus follows the visual order. Forms can be completed with the keyboard or a switch device.
- A touch anywhere that is not on a text field closes the keyboard (including on chips, buttons and list rows), and dragging a list closes it too. This is done once for the whole app, by a wrapper around the router, never per screen or per field. Number fields get a Done key.
- Do not convey anything by colour alone, by position alone, or by sound alone.
- Error messages say what went wrong and how to fix it, next to the field.

## 9. Checklist for a new or changed screen

Copy this into the pull request and tick it.

- [ ] Colours are theme roles only; roughly 60% surface, 30% containers, 10% accent; one filled primary button per section; tertiary at most once.
- [ ] Looked at in light and dark mode.
- [ ] Any new colour pair is in `contrast_test.dart`; important text is 7:1, other text 4.5:1, icons and borders 3:1.
- [ ] No raw spacing or radius number: only `Space`, `Corner`, `Gap`; `grid_test.dart` passes and its baseline did not go up.
- [ ] Shared card, field, buttons, confirm dialog, empty, error and loading states used; no new variant.
- [ ] Gutter 16, section gap 24, list gap 8, tap targets 48, content aligned to one left edge.
- [ ] Checked at 130% and 200% text size and at 360 px width: nothing clipped.
- [ ] Icon buttons have labels; nothing is told by colour alone.
- [ ] Destructive actions confirm; long actions show progress and cannot be double-sent.
- [ ] Screen listed in the design document.

## 10. Reusing this in another project

1. Copy this file to `docs/03-standards/ui-ux-rules.md`.
2. Copy `lib/app/tokens.dart` (spacing, radii, gaps), `lib/app/contrast.dart` (`contrastRatio`, `ensureContrast`), and the two tests `contrast_test.dart` and `grid_test.dart` (start `grid_baseline.txt` empty for a new project).
3. Reference this file from the agent context file under Standards and from the screen-building skill.
4. Change only the seed colour and the status colours; the rules stay.
