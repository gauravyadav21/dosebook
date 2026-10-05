---
name: spec-story
description: Turn a user story into acceptance criteria and API changes for human review. Use before implementing any story.
---

Input: a story from `docs/01-requirements/stories/`.

1. Restate the story in one sentence.
2. Write acceptance criteria as Given/When/Then, including negative cases (bad input, expired token, another user's data, network failure).
3. List API changes (routes, request/response, status codes) to be added to `docs/02-architecture/openapi.yaml`.
4. List data-model changes.
5. List open questions. Do not guess; stop and ask.

Output only the spec. Do not write implementation code.
