

## Reading accuracy with the live model (5 Oct 2026)
The three fake samples in `samples/` were uploaded through `POST /documents` with a throwaway account, under neutral file names (`rx1.png` to `rx3.png`) so the name could not hint at the content. The backend used the Gemini key in `backend/.env`. Expected values are those printed on the samples (the same values the demo reader holds).

| Sample | Fields expected | Read correctly | Notes |
|---|---|---|---|
| Sore throat (2 medicines, full doctor details) | 15 | 15 | Frequency came back as "3 times a day, after food"; the extra words are on the sample |
| Seasonal allergy (1 medicine) | 10 | 10 | Availability is not printed and was correctly left empty |
| Headache (1 medicine, doctor name only) | 7 | 7 | Phone and registration number are not printed and were correctly left empty |

32 of 32 fields. What this does and does not show: the samples are typed, clean and in English. Handwriting, photos at an angle, stamps, and other languages were not tried, and real prescriptions must not be sent to a free tier. Which of the two models answered is not recorded by the backend.

## End-to-end run on the Pixel emulator (5 Oct 2026, by the AI agent)
One pass as a new fake user, on the build that includes the fixes above.
- Worked: intro → Create account → acknowledgement → Upload → **system file picker** → live read shown on the review screen → schedule → Confirm → Timeline showed the new entry without switching tabs → Today showed the dose → marked Taken.
- Worked: Doctor tab with no phone number (Call opens nothing) → **Share** preview → system share sheet holding only the doctor's name and the "not verified" line → dismissed. Edit doctor, add a fake number → **Call** opened the phone's dialler with that number; no call was placed.
- Worked: new note saved and listed. Chat: "headache" recalled the user's own ibuprofen record; "how do I take ibuprofen" was refused with the dosage wording.
- Dark mode: chat and the prescription screen were looked at and are readable.
- **Fault found:** typing "cetirizine" gave "I can do two things..." because the lookup timed out. The refusal was the designed behaviour for an unchecked bare word, but the wording was misleading. Fixed with an end-to-end test first: the answer now says the lookup could not be done just now.
- How the file picker was driven: it ignores scripted taps on a file. Moving keyboard focus with the arrow keys and pressing Enter works. A first attempt picked `headache.png` rather than the intended file; the run continued with it.
- Not done on the device: the "Same doctor?" question (needs a second upload), editing and deleting a note, profile and allergies, feedback chips, stopping a course, own reminders, a real notification firing, and the medicine lookup succeeding (it timed out). These remain covered by widget and end-to-end tests only.
- Observation, not changed: the review screen shows "3 days" as read, but the course length on the schedule screen starts empty and has to be typed again. For the participant to decide whether it should be pre-filled.

## S13 (6 Oct 2026): judge access
- Tests first: 12 end-to-end tests (five storage cases under both `disk` and `database`, per-visitor rate limit behind a proxy, the upload limit) and 2 app tests. Six of the 12 failed before the code; the other six describe behaviour disk storage already had. Both app tests failed before the code.
- Run by the AI agent on the development Mac with the container's start command and settings: migrations applied, upload, byte-identical download, bytes found in `DocumentBlob`, fourth upload in a minute answered 429. A release APK built with a placeholder address.
- Not tested: the Dockerfile has never been built (no Docker on the Mac). Nothing is deployed, so the hosted server, TLS to Neon, the wake-up message against a sleeping server, the pipeline's `demo-apk` job and the release APK on a device are all untested.
