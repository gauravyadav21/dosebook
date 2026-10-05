# S2: Extract and confirm
As a user I review what the AI read so wrong data never enters my history.

Acceptance criteria
- Given an uploaded document, extraction returns condition, medicines (name, dose, frequency, duration), date, prescriber, each as editable fields.
- Extraction also returns the doctor's phone, registration number, specialty and availability when printed, each as an editable, optional field. They feed the doctor contact card (S9) only after Confirm.
- Given extraction fails or returns nothing, then the user can enter the data manually.
- Given the user edits and confirms, then only the confirmed values are saved.
- Given the user leaves without confirming, then nothing is added to the timeline.
- Given extracted medicines, the user confirms or edits the schedule: slots, before/after food, doses per day, course length. Missing schedule fields must be filled before Confirm is enabled.
