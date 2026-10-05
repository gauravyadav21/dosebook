# S13: Judges can try the app
As a judge I can install the app on an Android phone and use it against a hosted server, without setting anything up.

Requested by the participant on 6 Oct 2026. Choices made: an APK and a hosted backend (no web app); Render and Neon free tiers; live Gemini with tight limits; uploaded files kept in the database.

Acceptance criteria
- A backend and a PostgreSQL database run on free hosting, reachable over HTTPS. `/health` answers `{"status":"ok"}`.
- The database is brought up to the current migrations automatically on each deploy.
- A release APK built by the pipeline on `main` talks to that server. It needs no local set-up.
- Given the server restarts or is redeployed, confirmed prescriptions and the uploaded files are still there, and "View original document" still works.
- Uploaded files are served only to their owner, in either storage mode.
- Given the server sits behind the host's proxy, rate limits count per visitor, not once for everyone.
- Uploads have their own limit, lower than the general one, because each can spend model quota.
- Given the demo build, the upload screen says to upload only the sample prescriptions, never a real one.
- Given the demo server is asleep, the app says it may be waking and to try again, instead of only "check your connection".
- Given the model's free quota is used up, upload still works and the user enters the details by hand.
- No secret is in the repository, the container image or the pipeline file. Secrets are typed into the host's dashboard by the participant.
- Negative: no token -> 401 on every route but sign-up, sign-in and health, on the hosted server as locally.
- Negative: `FILE_STORAGE` set to anything but `disk` or `database` -> the server refuses to start.

API changes
- None in shape. `POST /documents` can now answer 429 from its own limit. `GET /documents/:id/file` answers 404 with "The original file is no longer stored" when the bytes are missing.

Data model changes
- New table `DocumentBlob` (documentId, data). `Document.storagePath` is optional.

Not in this story
- A web app, a custom domain, backups, monitoring, a signed release key, a Play Store listing.
