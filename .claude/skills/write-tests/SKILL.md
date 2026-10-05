---
name: write-tests
description: Draft failing tests from an approved spec before implementation.
---

Input: an approved spec (acceptance criteria).

1. One test per acceptance criterion, plus the negative cases listed.
2. Backend: Jest unit + e2e tests. Mobile: `flutter test`.
3. Tests must fail for the right reason before implementation exists. Run them and show the failure.
4. Use fake data only. No real secrets or personal data.
5. Note in `docs/06-qa/qa-strategy.md` how the human validated the tests.
