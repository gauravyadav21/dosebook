---
name: security-check
description: Security checklist pass over the codebase or a diff.
---

Check and report on:
- Secrets in code, config or git history (run gitleaks)
- Input validation on every endpoint (DTOs, ValidationPipe)
- Authentication on every non-public route; authorization so users cannot access others' data
- Rate limiting, CORS, error messages leaking internals
- Dependency vetting (npm audit, pub outdated)
- Logging of personal data

Output a table: finding, location, severity, suggested fix. Do not auto-fix.
