# Tour 2: upload to confirm

Follows the core journey: you pick a prescription photo, review what was read, set the schedule, and confirm. This is the longest tour; take it in the three parts marked below.

The rule to hold in mind throughout: **nothing read from the file is saved as your data until you press Confirm.**

## Part 1: upload and reading
1. **`mobile/lib/features/upload/upload_screen.dart`, `_pick`.** Calls `pickPrescriptionFile` from `mobile/lib/app/platform.dart` (a wrapper around the phone's file picker, replaceable in tests), then `api.upload`. On success it replaces itself with the review screen (`pushReplacement`), so pressing Back from review does not upload again.
2. **`mobile/lib/api/api.dart`, `upload`.** Sends the file as a multipart form. It goes through `_read` directly, not `_send`, so it does not signal "data changed": an upload alone changes nothing you can see.
3. **`backend/src/documents/documents.controller.ts`, `upload`.** `FileInterceptor` reads the file into memory with a 10 MB limit. `OversizeFilter` turns the framework's "413 too large" into the 400 the story asks for.
4. **`backend/src/documents/documents.service.ts`, `upload`.** In order:
   - no file, or too big: 400;
   - `sniffMime` (`file-type.ts`) looks at the file's first bytes to decide JPEG, PNG or PDF. The file name and the type the phone claims are ignored, because both can lie;
   - the file is written to `UPLOAD_DIR/<your id>/<random name>`. The original name is kept only as a label, never as part of a path;
   - a `Document` row is created;
   - the extractor is called inside a `try`. If it throws, the upload still succeeds and the status becomes `EXTRACTION_FAILED`.
5. **`backend/src/extraction/extraction.module.ts`.** Chooses the extractor once at start-up: `GeminiExtractor` if `GEMINI_API_KEY` is set, otherwise `DemoExtractor`.
   - `demo.extractor.ts` does not read the file at all. It returns fixed fake data when the file name contains `sore-throat`, `allergy` or `headache`, and nothing otherwise.
   - `gemini.extractor.ts` sends the file and a prompt through `backend/src/common/gemini.ts` and expects JSON back.
6. **`backend/src/extraction/normalize.ts`, `normalizeExtraction`.** The model's answer is not trusted. This keeps only the known fields, trims and caps text, drops a date that is not a real date, and returns nothing if there is no medicine. Whatever comes out is stored in `Document.extraction` for you to review. No other code reads that column as fact.

## Part 2: review and schedule (app only; nothing is sent)
7. **`mobile/lib/features/upload/review_screen.dart`.** Fills the fields from the extraction, or leaves them empty with the "could not read" banner. `_complete` decides whether "Next: schedule" is enabled: condition, date, prescriber, a valid phone if one is typed, and a name and dose for every medicine. `_next` packs what you typed into a `ReviewedPrescription` and opens the schedule screen. The server has not been called.
8. **`mobile/lib/features/upload/schedule_editor.dart`, `ScheduleDraft`.** Holds the times of day, food timing and course length for one medicine. `complete` is true only when all three are set and the length is 1 to 365. "Doses per day" is not typed; it is the number of times of day chosen, so the two can never disagree.
9. **`mobile/lib/features/upload/schedule_screen.dart`.** One editor per medicine. The Confirm button is disabled until every draft is complete, and a red line says what is missing.

## Part 3: confirm
10. **`schedule_screen.dart`, `_confirm`.** Builds the request body in `_body` (start date is today on the phone) and calls `api.confirm`.
11. **`backend/src/prescriptions/prescriptions.controller.ts`, `confirm`**, then the validation pipe against **`prescriptions.dto.ts`** (`ConfirmDto`, `ConfirmMedicineDto`, `DoctorDto`) and **`schedule.dto.ts`**. Unknown fields are rejected. Note `@IsDefined()` beside `@ValidateNested()` on `doctor` and `schedule`: without it a missing object slipped through and crashed. The app's checks in steps 7-9 are repeated here because the server never trusts the app.
12. **`backend/src/prescriptions/prescriptions.service.ts`, `confirm`.**
    - The document must be yours (otherwise 404) and not already confirmed (409).
    - Doses per day must equal the number of slots (400).
    - Then everything happens inside one `$transaction`: find or create the doctor, create the `Prescription`, create each `Medicine` with its `Schedule`, mark the document `CONFIRMED`. A transaction means all of it is saved or none of it.
13. **`prescriptions.service.ts`, `resolveDoctor`**, using **`backend/src/doctors/doctor-match.ts`, `matchDoctor`.** Same registration number, or same name and phone, links to the existing card. If only the name matches, the server refuses with 409 and the code `DOCTOR_NAME_MATCH`, plus the candidates. `fillMissing` adds details a later prescription prints, without overwriting existing ones.
14. **Back in `api.dart`, `_read`** turns that 409 into a `DoctorNameMatch` exception. **`schedule_screen.dart`** catches it and shows the "Same doctor?" dialog, then sends the confirm again with `sameDoctorId` or `newDoctor`.
15. **On success**: `_send` calls `onChanged`, so the Timeline behind reloads by itself (Tour 5); `_confirm` syncs reminders (Tour 3) and pops back to the first screen.
16. **`backend/src/prescriptions/prescriptions.views.ts`, `toPrescriptionView`** shapes the response, including the adherence count.

## Tests that prove it
- `backend/test/documents.e2e-spec.ts`: "rejects an unsupported file type by content, whatever the name says, and stores nothing", "does not use the original file name in the storage path", "keeps the upload and reports failure when the extractor throws".
- `backend/test/prescriptions.e2e-spec.ts`: "saves only the values the user confirmed, not what was extracted", "adds nothing to the timeline when the user leaves without confirming", "refuses to confirm the same document twice", and the table of invalid schedules.
- `backend/test/doctors.e2e-spec.ts`: 'asks "Same doctor?" when only the name matches, and never merges silently'.
- `mobile/test/widget_test.dart`: "keeps Confirm disabled until the schedule is complete, then saves and sets reminders".

## Agent defaults to question
- Reading happens during the upload request, so a slow model makes the upload wait.
- Files sit on the server's disk, unencrypted.
- Doses per day is derived from the times chosen; a prescription saying "2 tablets, 3 times a day" has no separate place for the 2 except the free-text dose.
- The name-only doctor match asks you; nothing cleverer.

## Things to try
1. Upload a text file renamed to `.png` in the app. Read the error, then find the line in `documents.service.ts` that produced it.
2. In `schedule.dto.ts`, raise the course-length maximum. Which test in `prescriptions.e2e-spec.ts` fails?
3. In `prescriptions.service.ts`, move the `document.update` line outside the transaction in your head: what could go wrong if the server stopped between the two?
4. Upload `samples/headache.png` after `sore-throat.png` and watch the "Same doctor?" dialog appear. Find the function that decided to ask.

## Check your understanding
1. Why is the file type decided from the bytes and not the name?
2. Which database column holds what the model read, and which code treats it as confirmed data?
3. Why are the app's form checks repeated in the DTOs?
4. What does the transaction in `confirm` protect against?
5. What stops two cards being created for the same doctor?

Answers: (1) A name or claimed type can be anything; the first bytes cannot be faked without breaking the file. (2) `Document.extraction`; no code treats it as confirmed, only Confirm creates prescriptions and medicines. (3) The server cannot assume requests come from this app. (4) A half-saved prescription, for example a prescription with no medicines or a document marked confirmed with nothing saved. (5) `matchDoctor`: registration number, or name plus phone; a name alone makes the server ask.
