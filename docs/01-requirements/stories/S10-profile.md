# S10: My profile
As a patient I keep my basic details in one place so that I have them to hand.

Acceptance criteria
- The profile holds: name, date of birth (age is shown), sex, height (cm), weight (kg), blood group, emergency contact name and phone, and long-term conditions in the user's own words. Every field is optional.
- The user's allergies (S4) are shown and edited on the same screen.
- Saving replaces the profile; an emptied field is cleared.
- The emergency contact has a Call button that opens the phone dialler.
- The app stores these details and does nothing else with them: no health score, no judgement on height or weight, and chat does not read long-term conditions.
- The profile cannot change the email or password.
- Negative: height outside 30-272 cm, weight outside 1-500 kg, unknown blood group or sex, date of birth malformed, in the future or before 1900, invalid phone, over-long text -> 400, nothing saved.
- Negative: no or expired token -> 401. One user never sees another's profile.
