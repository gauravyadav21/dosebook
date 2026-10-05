# S8: Doctor-vs-app messaging
As a patient I am regularly reminded what this app is not.

Acceptance criteria
- First run: the explanation screen must be acknowledged once; stored per user; shown again if the wording version changes.
- Chat screen shows a persistent short line; every chat answer ends with one short doctor-vs-app line.
- Extraction confirm screen shows "check against your paper prescription".
- Every escalation message uses the fixed wording from `what-we-do-and-dont.md`.
- Out-of-scope requests (diagnosis, new medicine, dose change, interaction judgement, severity beyond red-flag rules) get escalation and no medicine list; covered by tests.
- Negative: a model answer lacking the source label or doctor-vs-app line is rejected or repaired server-side.
