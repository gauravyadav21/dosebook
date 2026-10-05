# Mobile app

Flutter. Android first; the iOS project is present but has not been run. The web build is not maintained yet.

## Run on the Android emulator
Start the backend first (`../backend/README.md`), then:
```
flutter pub get
flutter emulators --launch Pixel_3a_API_32     # or any Android emulator
flutter run
```
The app talks to `http://10.0.2.2:3000` by default, which is the host machine as seen from the emulator. For a phone on the same network or a hosted backend:
```
flutter run --dart-define=API_BASE_URL=http://<address>:3000
```
Plain HTTP is allowed in debug builds only.

To try the upload flow, copy the fake samples to the emulator: `adb push ../samples/*.png /sdcard/Download/`.

## Check
```
flutter analyze && flutter test && flutter build apk --debug
```

## Layout
- `lib/api/`: server client and data classes
- `lib/app/`: session, fixed wording, formatting, wrappers for phone features
- `lib/features/`: one folder per area (auth, onboarding, home, today, timeline, upload, chat, notes, safety, doctors)
- `lib/reminders/`: notification planning (pure, tested) and the plugin wrapper
- `lib/widgets/`: shared cards and banners matching the Figma components

Design: `../docs/02-architecture/design.md`.
