# S1: Upload a prescription
As a user I upload a photo or PDF so my prescription is stored.

Acceptance criteria
- Given a signed-in user, when they upload a JPEG/PNG/PDF under 10 MB, then it is stored and an extraction starts.
- Given an unsupported type or oversize file, then 400 with a clear message and nothing stored.
- Given no or expired token, then 401.
- Given user A, when they request user B's document, then 404.
