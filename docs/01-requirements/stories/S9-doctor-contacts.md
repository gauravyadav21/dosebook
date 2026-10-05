# S9: Doctor contacts
As a patient I see who prescribed each prescription and keep a contact card per doctor, so that I can reach the right doctor without searching through old prescriptions.

Acceptance criteria
- Given a confirmed prescription with doctor details, the prescription detail has two tabs, Medicines and Doctor. The Doctor tab shows name, specialty, phone, registration number and availability.
- Doctor details are saved only after the user confirms them in the confirm step (S2). Name is required; phone, registration number, specialty and availability are optional.
- Details are shown as confirmed from the prescription, with the line "As printed on your prescription. Not verified by the app." The app does not verify a registration number.
- Availability is free text as printed. The app does not show live availability and does not book appointments.
- Given a doctor already exists for this user with the same registration number, or the same name and phone, the prescription links to the existing card and no second card is created.
- Given only the name matches an existing card, the confirm step asks "Same doctor?" and the user decides. Cards are never merged silently.
- The Doctors screen lists one card per doctor with name, specialty, phone, registration number and number of prescriptions.
- A doctor card lists every prescription recorded against that doctor, newest first, and each opens its prescription detail.
- Given a phone number, tapping Call opens the phone dialler with that number. Given no phone number, the card says "No number on this prescription", Call is unavailable, and the user can add a number.
- Share opens the system share sheet with the doctor's name, specialty, phone, registration number and availability only. It never includes the user's conditions, medicines, documents or notes. The preview says so before sending.
- The doctor card shows "In an emergency, call your local emergency number."
- The user can edit or delete a doctor card. Deleting a card does not delete its prescriptions.
- Negative: invalid phone format, empty name or over-long text -> 400.
- Negative: no or expired token -> 401.
- Negative: user A cannot read, change, share or list user B's doctors -> 404.
- Negative: a doctor card is never created from unconfirmed extraction output.

Data model note
- `Doctor`: id, userId, name, specialty, registrationNo, phone, availability. Unique per user on registrationNo when present.
- `Document.doctorId` links a prescription to its doctor.

Design: frames 15 to 19 in the Figma file, see `docs/02-architecture/design.md`.
