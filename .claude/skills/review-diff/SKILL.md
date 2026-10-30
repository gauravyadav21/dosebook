---
name: review-diff
description: Review a diff for correctness, tests, standards and security. Use a different model than the author.
---

1. Read the diff and the spec it implements.
2. Check against `docs/03-standards/coding-standards.md`.
3. Report: bugs, missing tests, missing validation or authorization, leaked secrets, new dependencies.
   For a Flutter screen, also report: data fetched outside `Loader`, a manual `reload()` after navigation, a change made outside `Api`, or a screen that would show stale data (see the `add-screen` skill). Also report UI breaks of `docs/03-standards/ui-ux-rules.md`: a fixed colour or raw spacing number in a screen, a new card, field or dialog variant instead of the shared one, text that fails contrast, a missing empty, error or loading state, or a raised `grid_baseline.txt`.
4. Rank findings by severity. No style nitpicks the linter already covers.
5. Do not edit code; report only.
