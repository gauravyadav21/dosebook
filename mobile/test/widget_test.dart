import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dosebook/api/models.dart';
import 'package:dosebook/app/platform.dart';
import 'package:dosebook/app/theme.dart';
import 'package:dosebook/app/wording.dart';
import 'package:dosebook/features/auth/sign_in_screen.dart';
import 'package:dosebook/features/auth/sign_up_screen.dart';
import 'package:dosebook/features/chat/chat_screen.dart';
import 'package:dosebook/features/doctors/doctors_screen.dart';
import 'package:dosebook/features/intro/intro_screen.dart';
import 'package:dosebook/features/notes/notes_screen.dart';
import 'package:dosebook/features/profile/profile_screen.dart';
import 'package:dosebook/features/safety/feedback_screen.dart';
import 'package:dosebook/features/today/own_reminder_screen.dart';
import 'package:dosebook/features/timeline/prescription_screen.dart';
import 'package:dosebook/features/timeline/timeline_screen.dart';
import 'package:dosebook/features/today/today_screen.dart';
import 'package:dosebook/features/upload/review_screen.dart';
import 'package:dosebook/features/upload/schedule_screen.dart';
import 'package:dosebook/features/upload/upload_screen.dart';
import 'package:dosebook/main.dart';
import 'package:dosebook/widgets/cards.dart';
import 'package:dosebook/widgets/common.dart';
import 'package:dosebook/widgets/logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';

Map<String, dynamic> meJson({required bool ackRequired}) => {
      'id': 'u1',
      'email': 'demo.patient@example.com',
      'acknowledgement': {'currentVersion': 1, 'acknowledgedVersion': ackRequired ? null : 1, 'required': ackRequired},
    };

/// Scrolls the screen's main list until [finder] is visible. Text fields are scrollables too, so the list is named explicitly.
Future<void> reveal(WidgetTester tester, Finder finder, [double delta = 200]) =>
    tester.scrollUntilVisible(finder, delta, scrollable: find.byType(Scrollable).first);

FilledButton filled(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Browse before sign-in, sign-in, sign-up and first run (S8, S11)', () {
    Future<TestApp> pumpGuestApp(WidgetTester tester, FakeBackend backend) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = TestApp(backend, signedIn: false);
      await tester.pumpWidget(App(session: app.session));
      await tester.pumpAndSettle();
      return app;
    }

    /// A backend where the demo user exists and has already acknowledged.
    FakeBackend signedUpBackend() => FakeBackend()
      ..on('POST /auth/login', (_) => {'accessToken': 'tok'})
      ..on('GET /me', (_) => meJson(ackRequired: false))
      ..on('GET /doses/today', (_) => {'date': '2026-10-04', 'doses': []})
      ..on('GET /prescriptions', (_) => [])
      ..on('GET /notes', (_) => [])
      ..on('GET /doctors', (_) => []);

    Future<void> fillSignIn(WidgetTester tester, {String password = 'long-enough-password'}) async {
      expect(find.text('Your records are visible only to you.'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'demo.patient@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), password);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the splash with logo, name and tagline while the app starts', (tester) async {
      final app = TestApp(FakeBackend(), signedIn: false)..session.loading = true;
      await tester.pumpWidget(App(session: app.session));
      await tester.pump();
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('DoseBook'), findsOneWidget);
      expect(find.text(tagline), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('opens on Today as a visitor, explains every tab and sends no request', (tester) async {
      final backend = FakeBackend();
      await pumpGuestApp(tester, backend);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Your doses for today'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Create account'), findsOneWidget);

      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      expect(find.text('Your medicine timeline'), findsOneWidget);
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(find.textContaining('You will be asked to sign in'), findsOneWidget);
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(find.text('Your own notes'), findsOneWidget);
      expect(backend.requests, isEmpty);
    });

    testWidgets('offers a visitor Sign in and Create account in the account menu, not Sign out', (tester) async {
      await pumpGuestApp(tester, FakeBackend());
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PopupMenuItem<String>, 'Sign in'), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<String>, 'Create account'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
      expect(find.text('My profile'), findsNothing);
    });

    testWidgets('asks a visitor to sign in before Upload, then continues to the upload screen', (tester) async {
      final backend = signedUpBackend();
      await pumpGuestApp(tester, backend);
      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();
      expect(backend.requests, isEmpty);
      await fillSignIn(tester);
      expect(find.byType(UploadScreen), findsOneWidget);
    });

    testWidgets('asks a visitor to sign in before My reminder, New note and Doctors', (tester) async {
      final backend = FakeBackend();
      await pumpGuestApp(tester, backend);
      await tester.tap(find.text('My reminder'));
      await tester.pumpAndSettle();
      expect(find.text('Your records are visible only to you.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New note'));
      await tester.pumpAndSettle();
      expect(find.text('Your records are visible only to you.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Doctors'));
      await tester.pumpAndSettle();
      expect(find.text('Your records are visible only to you.'), findsOneWidget);
      // Leaving sign-in with the back button opens nothing and sends nothing.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DoctorsScreen), findsNothing);
      expect(backend.requests, isEmpty);
    });

    testWidgets('opens My reminder after a visitor signs in from Today', (tester) async {
      await pumpGuestApp(tester, signedUpBackend());
      await tester.tap(find.text('My reminder'));
      await tester.pumpAndSettle();
      await fillSignIn(tester);
      expect(find.byType(OwnReminderScreen), findsOneWidget);
    });

    testWidgets('asks a visitor to sign in before chat sends, keeps the message, then sends it', (tester) async {
      final backend = signedUpBackend()
        ..on('POST /chat', (_) => {
              'kind': 'DECLINED',
              'text': 'I can only recall your own medicines or look up a medicine.',
              'footer': doctorVsApp,
              'medicines': [],
            });
      await pumpGuestApp(tester, backend);
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ibuprofen');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Your records are visible only to you.'), findsOneWidget);
      expect(backend.requests, isEmpty);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'ibuprofen'), findsOneWidget);
      expect(backend.requests, isEmpty);

      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      await fillSignIn(tester);
      expect(backend.bodies('POST /chat').single, {'message': 'ibuprofen'});
    });

    testWidgets('signs in from a visitor tab and shows the tab with data', (tester) async {
      final backend = signedUpBackend();
      final app = await pumpGuestApp(tester, backend);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await fillSignIn(tester);
      expect(find.text('No doses due today'), findsOneWidget);
      expect(find.text('Your doses for today'), findsNothing);
      expect(app.reminders.syncs, greaterThan(0));
    });

    testWidgets('signs in, shows the acknowledgement once, then opens Today', (tester) async {
      var acknowledged = false;
      final backend = FakeBackend()
        ..on('POST /auth/login', (_) => {'accessToken': 'tok'})
        ..on('GET /me', (_) => meJson(ackRequired: !acknowledged))
        ..on('PUT /me/acknowledgement', (_) {
          acknowledged = true;
          return meJson(ackRequired: false);
        })
        ..on('GET /doses/today', (_) => {'date': '2026-10-04', 'doses': []});
      final app = await pumpGuestApp(tester, backend);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await fillSignIn(tester);

      expect(find.text('What this app does not do'), findsOneWidget);
      expect(find.text('It does not prescribe or suggest new medicines'), findsOneWidget);
      expect(find.text(firstRunBanner), findsOneWidget);
      // The app cannot be used before acknowledging.
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      expect(backend.bodies('PUT /me/acknowledgement').single, {'version': 1});
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('No doses due today'), findsOneWidget);
      expect(app.reminders.syncs, greaterThan(0));
    });

    testWidgets('does not continue to Upload for a new user until the acknowledgement is accepted', (tester) async {
      final backend = FakeBackend()
        ..on('POST /auth/login', (_) => {'accessToken': 'tok'})
        ..on('GET /me', (_) => meJson(ackRequired: true));
      await pumpGuestApp(tester, backend);
      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();
      await fillSignIn(tester);
      expect(find.text('What this app does not do'), findsOneWidget);
      expect(find.byType(UploadScreen), findsNothing);
    });

    testWidgets('shows the server message when sign-in fails and stays on the screen', (tester) async {
      final backend = FakeBackend()..on('POST /auth/login', (_) => Reply(401, {'message': 'Email or password is incorrect'}));
      final app = await pumpGuestApp(tester, backend);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await fillSignIn(tester, password: 'wrong-password');
      expect(find.text('Email or password is incorrect'), findsOneWidget);
      expect(find.text('Your records are visible only to you.'), findsOneWidget);
      expect(app.session.signedIn, isFalse);
    });

    testWidgets('says so when the server cannot be reached during sign-in', (tester) async {
      final backend = FakeBackend()..on('POST /auth/login', (_) => throw Exception('socket closed'));
      final app = await pumpGuestApp(tester, backend);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await fillSignIn(tester);
      expect(find.textContaining('Could not reach the server'), findsOneWidget);
      expect(app.session.signedIn, isFalse);
    });

    testWidgets('hides the password by default and shows it on request', (tester) async {
      await pumpGuestApp(tester, FakeBackend());
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      bool obscured() => tester.widget<EditableText>(find.descendant(of: find.widgetWithText(TextFormField, 'Password'), matching: find.byType(EditableText))).obscureText;
      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(obscured(), isFalse);
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(obscured(), isTrue);
    });

    testWidgets('validates email and password before calling the server', (tester) async {
      final backend = FakeBackend();
      await pumpGuestApp(tester, backend);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Use at least 8 characters'), findsOneWidget);
      expect(backend.requests, isEmpty);
    });

    testWidgets('creates an account on the sign-up screen and shows the acknowledgement first', (tester) async {
      final backend = FakeBackend()
        ..on('POST /auth/register', (_) => {'accessToken': 'tok'})
        ..on('GET /me', (_) => meJson(ackRequired: true));
      final app = await pumpGuestApp(tester, backend);
      await tester.tap(find.widgetWithText(TextButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'new.patient@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'long-enough-password');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password again'), 'long-enough-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(backend.bodies('POST /auth/register').single, {'email': 'new.patient@example.com', 'password': 'long-enough-password'});
      expect(app.session.signedIn, isTrue);
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.text('What this app does not do'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('validates sign-up fields, including passwords that do not match, before calling the server', (tester) async {
      final backend = FakeBackend();
      await pumpGuestApp(tester, backend);
      await tester.tap(find.widgetWithText(TextButton, 'Create account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Use at least 8 characters'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'new.patient@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'long-enough-password');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password again'), 'another-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(backend.requests, isEmpty);
    });

    testWidgets('shows the server message when the email is already registered', (tester) async {
      final backend = FakeBackend()
        ..on('POST /auth/register', (_) => Reply(409, {'message': 'An account with this email already exists'}));
      final app = await pumpGuestApp(tester, backend);
      await tester.tap(find.widgetWithText(TextButton, 'Create account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'demo.patient@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'long-enough-password');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password again'), 'long-enough-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.text('An account with this email already exists'), findsOneWidget);
      expect(find.byType(SignUpScreen), findsOneWidget);
      expect(app.session.signedIn, isFalse);
    });

    testWidgets('moves between sign-in and sign-up without stacking screens', (tester) async {
      await pumpGuestApp(tester, FakeBackend());
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'I already have an account'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Your doses for today'), findsOneWidget);
    });

    testWidgets('returns to the visitor tabs after Sign out', (tester) async {
      final backend = signedUpBackend();
      final app = TestApp(backend)..session.me = Me.fromJson(meJson(ackRequired: false));
      await tester.pumpWidget(App(session: app.session));
      await tester.pumpAndSettle();
      expect(find.text('No doses due today'), findsOneWidget);
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Your doses for today'), findsOneWidget);
      expect(find.text('Your session ended. Sign in again.'), findsNothing);
      expect(app.reminders.clears, 1);
    });

    testWidgets('returns to the visitor tabs, says the session ended and clears reminders when it expires', (tester) async {
      final backend = FakeBackend()
        ..on('GET /doses/today', (_) => Reply(401, {'message': 'Session expired or invalid. Sign in again.'}));
      final app = TestApp(backend)..session.me = Me.fromJson(meJson(ackRequired: false));
      await tester.pumpWidget(App(session: app.session));
      await tester.pumpAndSettle();
      expect(find.text('Your doses for today'), findsOneWidget);
      expect(find.text('Your session ended. Sign in again.'), findsOneWidget);
      expect(app.reminders.clears, 1);
    });
  });

  group('Intro pages and appearance (S12)', () {
    Future<TestApp> pumpApp(WidgetTester tester, FakeBackend backend, {bool signedIn = false, bool intro = true}) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = TestApp(backend, signedIn: signedIn, intro: intro);
      await tester.pumpWidget(App(session: app.session));
      await tester.pumpAndSettle();
      return app;
    }

    Brightness brightness(WidgetTester tester) => Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

    testWidgets('shows the intro to a visitor at start, before the tabs, and sends no request', (tester) async {
      final backend = FakeBackend();
      await pumpApp(tester, backend);
      expect(find.byType(IntroScreen), findsOneWidget);
      expect(find.text('Your prescriptions in one timeline'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(backend.requests, isEmpty);
    });

    testWidgets('walks the four pages in order and ends on what the app never does, in the fixed wording', (tester) async {
      await pumpApp(tester, FakeBackend());
      expect(find.text('Your prescriptions in one timeline'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Reminders as written on your prescription'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('What worked for you'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('What DoseBook never does'), findsOneWidget);
      for (final line in doesNotLines) {
        expect(find.text(line), findsOneWidget);
      }
      expect(find.text(firstRunBanner), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Next'), findsNothing);
      expect(find.text('Skip'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
      await tester.pumpAndSettle();
      expect(find.byType(IntroScreen), findsNothing);
      expect(find.text('Your doses for today'), findsOneWidget);
    });

    testWidgets('can be swiped from page to page', (tester) async {
      await pumpApp(tester, FakeBackend());
      await tester.drag(find.byType(PageView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(find.text('Reminders as written on your prescription'), findsOneWidget);
    });

    testWidgets('Skip goes straight to the visitor tabs and sends no request', (tester) async {
      final backend = FakeBackend();
      await pumpApp(tester, backend);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.byType(IntroScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(backend.requests, isEmpty);
    });

    testWidgets('Sign in on the intro opens the sign-in screen over the visitor tabs', (tester) async {
      await pumpApp(tester, FakeBackend());
      await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Your doses for today'), findsOneWidget);
    });

    testWidgets('is not shown to a signed-in user, nor again after Sign out in the same run', (tester) async {
      final backend = FakeBackend()..on('GET /doses/today', (_) => {'date': '2026-10-04', 'doses': []});
      await pumpApp(tester, backend, signedIn: true);
      expect(find.byType(IntroScreen), findsNothing);
      expect(find.text('No doses due today'), findsOneWidget);
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byType(IntroScreen), findsNothing);
      expect(find.text('Your doses for today'), findsOneWidget);
    });

    testWidgets('reopens from About DoseBook in the account menu and closes back to where the user was', (tester) async {
      await pumpApp(tester, FakeBackend(), intro: false);
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About DoseBook'));
      await tester.pumpAndSettle();
      expect(find.text('Your prescriptions in one timeline'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.byType(IntroScreen), findsNothing);
      expect(find.text('Your doses for today'), findsOneWidget);
    });

    testWidgets('follows the phone when no appearance was chosen', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final app = await pumpApp(tester, FakeBackend(), intro: false);
      expect(app.session.themeMode, ThemeMode.system);
      expect(brightness(tester), Brightness.dark);
    });

    testWidgets('switches to dark from Appearance at once, marks the choice and saves it on the phone', (tester) async {
      final app = await pumpApp(tester, FakeBackend(), intro: false);
      expect(brightness(tester), Brightness.light);
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(app.session.themeMode, ThemeMode.dark);
      expect(brightness(tester), Brightness.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      // No server call: the choice belongs to the phone.
      expect(app.backend.requests, isEmpty);
    });

    testWidgets('restores a saved appearance at start-up', (tester) async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final app = TestApp(FakeBackend(), signedIn: false)..session.loading = true;
      await tester.pumpWidget(App(session: app.session));
      await tester.runAsync(app.session.restore);
      await tester.pumpAndSettle();
      expect(app.session.themeMode, ThemeMode.dark);
      expect(brightness(tester), Brightness.dark);
    });

    testWidgets('keeps the brand colour on the splash in dark mode', (tester) async {
      final app = TestApp(FakeBackend(), signedIn: false)
        ..session.loading = true
        ..session.themeMode = ThemeMode.dark;
      await tester.pumpWidget(App(session: app.session));
      await tester.pump();
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, brandScheme.primary);
    });

    testWidgets('shows a visitor tab, sign-in and the intro in dark mode at phone width without overflow', (tester) async {
      final app = await pumpApp(tester, FakeBackend());
      await app.session.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.dark);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Today (S6, S7)', () {
    final now = DateTime(2026, 10, 4, 9);

    testWidgets('groups doses by part of day and labels own reminders as the user\'s own', (tester) async {
      final backend = FakeBackend()
        ..on('GET /doses/today', (_) => {
              'date': '2026-10-04',
              'doses': [
                doseJson(status: 'TAKEN'),
                doseJson(slot: 'NOON'),
                doseJson(medicineId: 'm9', name: 'Vitamin D3', slot: '13:30', group: 'NOON', origin: 'YOUR_REMINDER', food: null),
              ],
            });
      await pumpScreen(tester, backend, TodayScreen(now: now));

      expect(find.text('Sunday 4 October · 1 of 3 doses marked'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Noon'), findsOneWidget);
      expect(find.text('Night'), findsNothing);
      expect(find.text('As prescribed'), findsNWidgets(2));
      expect(find.text('Your reminder · Self-added'), findsOneWidget);
      expect(find.textContaining('Taken at'), findsOneWidget);
      expect(backend.requests.first.url.queryParameters['date'], '2026-10-04');
    });

    testWidgets('marks a dose taken, reloads and re-syncs reminders', (tester) async {
      var status = 'DUE';
      final backend = FakeBackend()
        ..on('GET /doses/today', (_) => {'date': '2026-10-04', 'doses': [doseJson(status: status)]})
        ..on('POST /doses/mark', (_) {
          status = 'TAKEN';
          return {};
        });
      final app = await pumpScreen(tester, backend, TodayScreen(now: now));

      await tester.tap(find.widgetWithText(FilledButton, 'Taken'));
      await tester.pumpAndSettle();

      expect(backend.bodies('POST /doses/mark').single, {
        'medicineId': 'm1',
        'date': '2026-10-04',
        'slot': 'MORNING',
        'status': 'TAKEN',
      });
      expect(find.textContaining('Taken at'), findsOneWidget);
      expect(app.reminders.syncs, 1);
    });

    testWidgets('shows an error and keeps the dose due when marking fails', (tester) async {
      final backend = FakeBackend()
        ..on('GET /doses/today', (_) => {'date': '2026-10-04', 'doses': [doseJson()]})
        ..on('POST /doses/mark', (_) => Reply(400, {'message': 'No dose is scheduled for this medicine at that date and time'}));
      await pumpScreen(tester, backend, TodayScreen(now: now));
      await tester.tap(find.text('Skipped'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No dose is scheduled'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Taken'), findsOneWidget);
    });

    testWidgets('offers a retry when the server cannot be reached', (tester) async {
      var fail = true;
      final backend = FakeBackend()
        ..on('GET /doses/today', (_) {
          if (fail) throw Exception('offline');
          return {'date': '2026-10-04', 'doses': []};
        });
      await pumpScreen(tester, backend, TodayScreen(now: now));
      expect(find.textContaining('Could not reach the server'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No doses due today'), findsOneWidget);
    });
  });

  group('Timeline (S3)', () {
    testWidgets('explains how to upload when there is no history', (tester) async {
      final backend = FakeBackend()..on('GET /prescriptions', (_) => []);
      await pumpScreen(tester, backend, const TimelineScreen());
      expect(find.text('No history yet'), findsOneWidget);
      expect(find.textContaining('Upload a prescription'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
    });

    testWidgets('lists entries in the order the server returns, with condition, medicines and prescriber', (tester) async {
      final backend = FakeBackend()
        ..on('GET /prescriptions', (_) => [
              prescriptionJson(),
              prescriptionJson(id: 'p2', condition: 'Headache', date: '2025-08-18'),
            ]);
      await pumpScreen(tester, backend, const TimelineScreen());
      final entries = tester.widgetList<TimelineEntry>(find.byType(TimelineEntry)).toList();
      expect(entries.map((e) => e.prescription.condition), ['Sore throat', 'Headache']);
      expect(find.text('12 Mar 2026'), findsOneWidget);
      expect(find.text('Prescribed by Dr. A. Mehra'), findsNWidgets(2));
      expect(find.text('Doses taken: 2 of 15'), findsNWidgets(2));
      expect(find.text('From prescription'), findsNWidgets(2));
    });
  });

  group('Upload and confirm (S1, S2, S9)', () {
    testWidgets('warns to upload only the samples on the demo build, and says nothing of it otherwise (S13)', (tester) async {
      await pumpScreen(tester, FakeBackend(), const UploadScreen(demo: true));
      expect(find.text(demoUploadNote), findsOneWidget);
      await pumpScreen(tester, FakeBackend(), const UploadScreen(demo: false));
      expect(find.text(demoUploadNote), findsNothing);
    });

    testWidgets('shows the server reason when a file is rejected and says nothing was stored', (tester) async {
      pickPrescriptionFile = () async => PickedFile('notes.docx', Uint8List.fromList([1, 2, 3]));
      final backend = FakeBackend()
        ..on('POST /documents', (_) => Reply(400, {'message': 'File type is not supported. Use a JPEG, PNG or PDF.'}));
      await pumpScreen(tester, backend, const UploadScreen());
      await tester.tap(find.text('Browse files'));
      await tester.pumpAndSettle();
      expect(find.text('File type is not supported. Use a JPEG, PNG or PDF. Nothing was stored.'), findsOneWidget);
      expect(find.byType(ReviewScreen), findsNothing);
    });

    testWidgets('opens the review screen with the extracted fields after upload', (tester) async {
      pickPrescriptionFile = () async => PickedFile('sore-throat.png', Uint8List.fromList([1, 2, 3]));
      final backend = FakeBackend()
        ..on('POST /documents', (_) => Reply(201, {
              'id': 'doc1',
              'fileName': 'sore-throat.png',
              'status': 'EXTRACTED',
              'extraction': {
                'condition': 'Sore throat',
                'date': '2026-03-12',
                'doctor': {'name': 'Dr. A. Mehra', 'phone': '+91 00000 00101'},
                'medicines': [
                  {'name': 'Paracetamol', 'dose': '500 mg, 1 tablet', 'frequency': '3 times a day', 'duration': '5 days'},
                ],
              },
            }));
      await pumpScreen(tester, backend, const UploadScreen());
      await tester.tap(find.text('Browse files'));
      await tester.pumpAndSettle();

      expect(find.text('Check what we read'), findsOneWidget);
      expect(find.text(checkAgainstPaper), findsOneWidget);
      expect(find.text('Sore throat'), findsOneWidget);
      expect(find.text('12 Mar 2026'), findsOneWidget);
      expect(find.text('Dr. A. Mehra'), findsOneWidget);
      expect(find.text('+91 00000 00101'), findsOneWidget);
      expect(find.text('Paracetamol'), findsOneWidget);
    });

    testWidgets('offers manual entry when reading failed, and keeps Next disabled until the details are filled', (tester) async {
      final backend = FakeBackend();
      final document = UploadedDocument(id: 'doc1', fileName: 'x.png', status: 'EXTRACTION_FAILED');
      await pumpScreen(tester, backend, ReviewScreen(document: document));

      expect(find.text('Enter details'), findsOneWidget);
      expect(find.text(couldNotRead), findsOneWidget);
      expect(filled(tester, 'Next: schedule').onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Condition'), 'Cough');
      await tester.enterText(find.widgetWithText(TextField, 'Prescriber'), 'Dr. S. Khan');
      await tester.enterText(find.widgetWithText(TextField, 'Medicine 1'), 'Syrup');
      await tester.enterText(find.widgetWithText(TextField, 'Dose'), '5 ml');
      await tester.pump();
      // The date is still missing.
      expect(filled(tester, 'Next: schedule').onPressed, isNull);
      // Review alone never talks to the server.
      expect(backend.requests, isEmpty);
    });

    testWidgets('flags an invalid doctor phone number before the user can continue', (tester) async {
      final document = UploadedDocument(
        id: 'doc1',
        fileName: 'sore-throat.png',
        status: 'EXTRACTED',
        extraction: Extraction(
          condition: 'Sore throat',
          date: '2026-03-12',
          doctor: {'name': 'Dr. A. Mehra'},
          medicines: [ExtractedMedicine(name: 'Paracetamol', dose: '500 mg')],
        ),
      );
      await pumpScreen(tester, FakeBackend(), ReviewScreen(document: document));
      expect(filled(tester, 'Next: schedule').onPressed, isNotNull);
      await tester.enterText(find.widgetWithText(TextField, "Doctor's phone"), 'call the clinic');
      await tester.pump();
      expect(find.text('Check the number'), findsOneWidget);
      expect(filled(tester, 'Next: schedule').onPressed, isNull);
    });

    ReviewedPrescription reviewed() => ReviewedPrescription(
          documentId: 'doc1',
          condition: 'Sore throat',
          date: '2026-03-12',
          doctor: {'name': 'Dr. A. Mehra'},
          medicines: [MedicineDraft(name: 'Paracetamol', dose: '500 mg', frequency: '3 times a day')],
        );

    Future<void> fillSchedule(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilterChip, 'Morning'));
      await tester.tap(find.widgetWithText(FilterChip, 'Night'));
      await tester.tap(find.widgetWithText(FilterChip, 'After food'));
      await tester.enterText(find.widgetWithText(TextField, 'Course length'), '5');
      await tester.pump();
    }

    testWidgets('keeps Confirm disabled until the schedule is complete, then saves and sets reminders', (tester) async {
      final backend = FakeBackend()..on('POST /documents/doc1/confirm', (_) => Reply(201, prescriptionJson()));
      final app = await pumpScreen(tester, backend, ScheduleScreen(reviewed: reviewed()));

      expect(find.text(remindersFollowPrescription), findsOneWidget);
      expect(filled(tester, 'Confirm and set reminders').onPressed, isNull);
      expect(find.textContaining('choose the times of day'), findsOneWidget);
      expect(backend.requests, isEmpty);

      await fillSchedule(tester);
      expect(filled(tester, 'Confirm and set reminders').onPressed, isNotNull);
      await tester.tap(find.text('Confirm and set reminders'));
      await tester.pumpAndSettle();

      final body = backend.bodies('POST /documents/doc1/confirm').single as Map<String, dynamic>;
      expect(body['condition'], 'Sore throat');
      expect(body['doctor'], {'name': 'Dr. A. Mehra'});
      final medicine = (body['medicines'] as List).single as Map<String, dynamic>;
      expect(medicine['name'], 'Paracetamol');
      expect(medicine.containsKey('duration'), isFalse);
      final schedule = medicine['schedule'] as Map<String, dynamic>;
      expect(schedule['slots'], ['MORNING', 'NIGHT']);
      expect(schedule['food'], 'AFTER_FOOD');
      expect(schedule['dosesPerDay'], 2);
      expect(schedule['courseDays'], 5);
      expect(app.reminders.syncs, 1);
    });

    testWidgets('asks "Same doctor?" when only the name matches and links the chosen card', (tester) async {
      var calls = 0;
      final backend = FakeBackend()
        ..on('POST /documents/doc1/confirm', (_) {
          calls++;
          return calls == 1
              ? Reply(409, {'code': 'DOCTOR_NAME_MATCH', 'message': 'x', 'candidates': [doctorJson()]})
              : Reply(201, prescriptionJson());
        });
      await pumpScreen(tester, backend, ScheduleScreen(reviewed: reviewed()));
      await fillSchedule(tester);
      await tester.tap(find.text('Confirm and set reminders'));
      await tester.pumpAndSettle();

      expect(find.text('Same doctor?'), findsOneWidget);
      expect(find.text('MH-00000-DEMO', findRichText: true), findsNothing);
      expect(find.text('Reg. no. MH-00000-DEMO'), findsOneWidget);
      await tester.tap(find.text('Yes, same doctor'));
      await tester.pumpAndSettle();

      final bodies = backend.bodies('POST /documents/doc1/confirm');
      expect(bodies, hasLength(2));
      expect((bodies[0] as Map).containsKey('sameDoctorId'), isFalse);
      expect((bodies[1] as Map)['sameDoctorId'], 'd1');
    });

    testWidgets('creates a new card when the user answers "new doctor", and saves nothing on Cancel', (tester) async {
      var calls = 0;
      final backend = FakeBackend()
        ..on('POST /documents/doc1/confirm', (_) {
          calls++;
          return calls.isOdd && calls < 4
              ? Reply(409, {'code': 'DOCTOR_NAME_MATCH', 'message': 'x', 'candidates': [doctorJson()]})
              : Reply(201, prescriptionJson());
        });
      final app = await pumpScreen(tester, backend, ScheduleScreen(reviewed: reviewed()));
      await fillSchedule(tester);

      await tester.tap(find.text('Confirm and set reminders'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.bodies('POST /documents/doc1/confirm'), hasLength(1));
      expect(app.reminders.syncs, 0);

      calls = 2;
      await tester.tap(find.text('Confirm and set reminders'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No, new doctor'));
      await tester.pumpAndSettle();
      expect((backend.bodies('POST /documents/doc1/confirm').last as Map)['newDoctor'], true);
    });
  });

  group('Chat (S5, S8)', () {
    const footer = "I only recall your own records. I don't prescribe. Check with your doctor if anything has changed.";

    Future<void> ask(WidgetTester tester, String message) async {
      await tester.enterText(find.byType(TextField), message);
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
    }

    Map<String, dynamic> recalled({String id = 'm1', String name = 'Paracetamol', String? feedback}) => {
          'medicineId': id,
          'name': name,
          'dose': '500 mg, 1 tablet',
          'frequency': '3 times a day',
          'duration': '5 days',
          'sourceLabel': 'From prescription',
          'prescriber': 'Dr. A. Mehra',
          'date': '2026-03-12',
          'condition': 'Sore throat',
          'feedback': feedback,
        };

    testWidgets('always shows the doctor-vs-app line', (tester) async {
      await pumpScreen(tester, FakeBackend(), const ChatScreen());
      expect(find.text(doctorVsApp), findsOneWidget);
    });

    testWidgets('shows recalled medicines with recorded feedback and never asks for feedback', (tester) async {
      final backend = FakeBackend()
        ..on('POST /chat', (_) => {
              'kind': 'RECALL',
              'text': 'Here is what your own records show for this.',
              'excludedCount': 0,
              'footer': footer,
              'medicines': [recalled(feedback: 'WORKED'), recalled(id: 'm2', name: 'Cetirizine')],
            });
      final app = await pumpScreen(tester, backend, const ChatScreen());
      await ask(tester, 'I have a sore throat');

      expect(backend.bodies('POST /chat').single, {'message': 'I have a sore throat'});
      // The list jumps to the newest content; go back up to the start of the answer.
      await reveal(tester, find.textContaining("I don't prescribe"), -200);
      expect(find.textContaining("I don't prescribe"), findsOneWidget);
      expect(find.text('Sore throat · Dr. A. Mehra · 12 Mar 2026'), findsNWidgets(2));
      expect(find.text('Your feedback: Worked'), findsOneWidget);
      expect(find.text('No feedback recorded'), findsOneWidget);
      expect(find.byType(FeedbackChips), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byType(EscalationCard), findsNothing);
      // Asking a question changes no data, so nothing is reloaded.
      expect(app.session.revision, 0);
    });

    testWidgets('shows a medicine lookup: own record, what it is prescribed for, how to keep it, disclaimer, allergy flag', (tester) async {
      const disclaimer = 'General information from an AI model, not checked by a doctor. Not advice. Ask your doctor or pharmacist.';
      final backend = FakeBackend()
        ..on('POST /chat', (_) => {
              'kind': 'MEDICINE_INFO',
              'text': 'Here is what your records show for Paracetamol.',
              'excludedCount': 0,
              'medicineName': 'Paracetamol',
              'generalInfo': {'usedFor': 'Usually prescribed for pain and fever.', 'storage': 'Keep in a cool, dry place.', 'disclaimer': disclaimer},
              'allergyMatch': true,
              'footer': footer,
              'medicines': [recalled(feedback: 'SIDE_EFFECT')],
            });
      await pumpScreen(tester, backend, const ChatScreen());
      await ask(tester, 'what is paracetamol');
      await reveal(tester, find.text('Here is what your records show for Paracetamol.'), -200);

      expect(find.text('This medicine matches an allergy you listed.'), findsOneWidget);
      expect(find.text('About Paracetamol'), findsOneWidget);
      expect(find.text('Usually prescribed for'), findsOneWidget);
      expect(find.text('Usually prescribed for pain and fever.'), findsOneWidget);
      expect(find.text('How to keep it'), findsOneWidget);
      expect(find.text('Keep in a cool, dry place.'), findsOneWidget);
      expect(find.text(disclaimer), findsOneWidget);
      await reveal(tester, find.text('Your feedback: Side effect'));
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('says when a medicine has no general information and no record', (tester) async {
      final backend = FakeBackend()
        ..on('POST /chat', (_) => {
              'kind': 'MEDICINE_INFO',
              'text': 'ibuprofen is not in your own records. No general information is saved for this medicine yet.',
              'excludedCount': 0,
              'medicineName': 'ibuprofen',
              'generalInfo': null,
              'allergyMatch': false,
              'footer': footer,
              'medicines': [],
            });
      await pumpScreen(tester, backend, const ChatScreen());
      await ask(tester, 'what is ibuprofen');
      expect(find.textContaining('not in your own records'), findsOneWidget);
      expect(find.textContaining('About '), findsNothing);
      expect(find.byType(MedicineCard), findsNothing);
    });

    testWidgets('leaves out "How to keep it" when no storage information is saved', (tester) async {
      final backend = FakeBackend()
        ..on('POST /chat', (_) => {
              'kind': 'MEDICINE_INFO',
              'text': 'Oldmed is not in your own records.',
              'excludedCount': 0,
              'medicineName': 'Oldmed',
              'generalInfo': {'usedFor': 'Usually prescribed for allergies.', 'storage': null, 'disclaimer': 'Not advice.'},
              'allergyMatch': false,
              'footer': footer,
              'medicines': [],
            });
      await pumpScreen(tester, backend, const ChatScreen());
      await ask(tester, 'what is oldmed');
      expect(find.text('Usually prescribed for allergies.'), findsOneWidget);
      expect(find.text('How to keep it'), findsNothing);
      expect(find.text('Not advice.'), findsOneWidget);
    });

    testWidgets('shows the dosage refusal as a plain message, with no medicine and no escalation card', (tester) async {
      const refusal = "I can't tell you how much to take. Taking a medicine without a doctor's advice is not recommended. Please visit your doctor.";
      final backend = FakeBackend()
        ..on('POST /chat', (_) => {'kind': 'DECLINED', 'reason': 'DOSAGE', 'text': refusal, 'excludedCount': 0, 'footer': footer, 'medicines': []});
      await pumpScreen(tester, backend, const ChatScreen());
      await ask(tester, 'how much paracetamol can I take');
      expect(find.text(refusal), findsOneWidget);
      expect(find.byType(MedicineCard), findsNothing);
      expect(find.textContaining('About '), findsNothing);
    });

    testWidgets('shows the decline message for anything else', (tester) async {
      const declined = "I can do two things: show what you took before for a symptom, or look up a medicine. I can't help with anything else.";
      final backend = FakeBackend()
        ..on('POST /chat', (_) => {'kind': 'DECLINED', 'text': declined, 'excludedCount': 0, 'footer': footer, 'medicines': []});
      await pumpScreen(tester, backend, const ChatScreen());
      await ask(tester, 'tell me a joke');
      expect(find.text(declined), findsOneWidget);
      expect(find.byType(MedicineCard), findsNothing);
      expect(find.byType(EscalationCard), findsNothing);
    });

    testWidgets('shows only the fixed escalation card for a red-flag symptom, with no medicine', (tester) async {
      final backend = FakeBackend()
        ..on('POST /chat', (_) => {
              'kind': 'ESCALATION',
              'reason': 'RED_FLAG',
              'text': "This needs a doctor's attention. I can't prescribe or advise treatment. Please contact your doctor or emergency services.",
              'medicines': [],
              'excludedCount': 0,
              'emergency': emergencyLine,
              'footer': 'x',
            });
      await pumpScreen(tester, backend, const ChatScreen());
      await ask(tester, 'I have chest pain and trouble breathing');

      expect(find.byType(EscalationCard), findsOneWidget);
      expect(find.text(escalationTitle), findsOneWidget);
      expect(find.text(escalationBody), findsOneWidget);
      expect(find.text(emergencyLine), findsOneWidget);
      expect(find.byType(MedicineCard), findsNothing);
    });

    testWidgets('does not send an empty message', (tester) async {
      final backend = FakeBackend();
      await pumpScreen(tester, backend, const ChatScreen());
      await ask(tester, '   ');
      expect(backend.requests, isEmpty);
    });
  });

  group('Open notes (S7)', () {
    Map<String, dynamic> note(String id, String text) =>
        {'id': id, 'text': text, 'createdAt': '2026-10-04T05:00:00.000Z', 'updatedAt': '2026-10-04T05:00:00.000Z'};

    testWidgets('lists notes as plain text, with no medicine fields or tags', (tester) async {
      final backend = FakeBackend()..on('GET /notes', (_) => [note('n1', 'Ask about the cough next visit.')]);
      await pumpScreen(tester, backend, const NotesScreen());
      expect(find.text('Ask about the cough next visit.'), findsOneWidget);
      expect(find.text('Edited 04 Oct 2026'), findsOneWidget);
      expect(find.text('Self-added'), findsNothing);
      expect(find.byType(MedicineCard), findsNothing);
    });

    testWidgets('the editor is a single text field; Save is disabled while it is empty', (tester) async {
      final backend = FakeBackend()..on('POST /notes', (_) => Reply(201, note('n1', 'x')));
      await pumpScreen(tester, backend, const NoteEditScreen());
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save')).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Line one\nLine two');
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();
      expect(backend.bodies('POST /notes').single, {'text': 'Line one\nLine two'});
    });

    testWidgets('edits and deletes an existing note after confirmation', (tester) async {
      final backend = FakeBackend()
        ..on('PATCH /notes/n1', (_) => note('n1', 'x'))
        ..on('DELETE /notes/n1', (_) => Reply(204));
      final existing = Note.fromJson(note('n1', 'Old text'));
      await pumpScreen(tester, backend, NoteEditScreen(note: existing));
      expect(find.text('Old text'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.requests, isEmpty);

      await tester.tap(find.byTooltip('Delete note'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(backend.requests.single.method, 'DELETE');
    });
  });

  group('Own reminders (S7)', () {
    final reminder = {
      ...medicineJson(id: 'r1', name: 'Vitamin D3', source: 'SELF'),
      'dose': '1 capsule',
      'frequency': null,
      'duration': null,
      'schedule': {...scheduleJson(), 'slots': ['MORNING'], 'times': ['21:30'], 'food': null, 'courseDays': null, 'endDate': null},
    };

    testWidgets('saves a new reminder with the dose exactly as typed', (tester) async {
      final backend = FakeBackend()..on('POST /own-reminders', (_) => Reply(201, reminder));
      await pumpScreen(tester, backend, const OwnReminderScreen());

      expect(find.text('Self-added'), findsOneWidget);
      expect(find.text(ownReminder), findsOneWidget);
      expect(filled(tester, 'Save').onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Medicine name'), 'Vitamin D3');
      await tester.enterText(find.widgetWithText(TextField, 'Dose (optional, your own words)'), ' approx 1-2 caps?? ');
      await tester.pump();
      // A name alone is not enough: a reminder needs at least one time.
      expect(find.text('Choose at least one time.'), findsOneWidget);
      expect(filled(tester, 'Save').onPressed, isNull);

      await tester.tap(find.widgetWithText(FilterChip, 'Morning'));
      await tester.pump();
      await reveal(tester, find.widgetWithText(FilledButton, 'Save'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final body = backend.bodies('POST /own-reminders').single as Map<String, dynamic>;
      expect(body['name'], 'Vitamin D3');
      expect(body['dose'], ' approx 1-2 caps?? ');
      expect(body['slots'], ['MORNING']);
      expect(body['times'], isEmpty);
    });

    testWidgets('Today offers "My reminder" and lets an own reminder be edited from its dose', (tester) async {
      final backend = FakeBackend()
        ..on('GET /doses/today', (_) => {
              'date': '2026-10-04',
              'doses': [
                doseJson(),
                doseJson(medicineId: 'r1', name: 'Vitamin D3', origin: 'YOUR_REMINDER', food: null),
              ],
            })
        ..on('GET /own-reminders', (_) => [reminder]);
      await pumpScreen(tester, backend, TodayScreen(now: DateTime(2026, 10, 4, 9)));

      expect(find.text('My reminder'), findsOneWidget);
      // Only the user's own reminder can be edited here, never a prescribed dose.
      expect(find.byTooltip('Edit my reminder for Vitamin D3'), findsOneWidget);
      expect(find.byTooltip('Edit my reminder for Paracetamol'), findsNothing);

      await tester.tap(find.byTooltip('Edit my reminder for Vitamin D3'));
      await tester.pumpAndSettle();
      expect(find.text('Edit my reminder'), findsOneWidget);
      expect(find.text('9:30 pm'), findsOneWidget);
    });
  });

  group('Profile (S10) and allergies (S4)', () {
    Map<String, dynamic> profileJson([Map<String, dynamic> overrides = const {}]) => {
          'email': 'demo.patient@example.com',
          'name': null,
          'dateOfBirth': null,
          'sex': null,
          'heightCm': null,
          'weightKg': null,
          'bloodGroup': null,
          'emergencyName': null,
          'emergencyPhone': null,
          'conditions': null,
          ...overrides,
        };

    test('age is whole years, counted to the birthday', () {
      expect(ageOn('1990-05-17', DateTime(2026, 5, 16)), 35);
      expect(ageOn('1990-05-17', DateTime(2026, 5, 17)), 36);
      expect(ageOn(null, DateTime(2026, 1, 1)), isNull);
      expect(ageOn('2999-01-01', DateTime(2026, 1, 1)), isNull);
    });

    testWidgets('shows saved details and says the app does not advise from them', (tester) async {
      final backend = FakeBackend()
        ..on('GET /me/profile', (_) => profileJson({'name': 'Demo Patient', 'heightCm': 165.5, 'weightKg': 62, 'bloodGroup': 'O+'}))
        ..on('GET /allergies', (_) => []);
      await pumpScreen(tester, backend, const ProfileScreen());
      expect(find.text('demo.patient@example.com'), findsOneWidget);
      expect(find.text('Demo Patient'), findsOneWidget);
      expect(find.text('165.5'), findsOneWidget);
      expect(find.text('62'), findsOneWidget);
      expect(find.text('O+'), findsOneWidget);
      await reveal(tester, find.textContaining('does not check them or advise from them'));
    });

    testWidgets('saves the profile, sending empty fields as null, and blocks out-of-range values', (tester) async {
      Map<String, dynamic> saved = profileJson();
      final backend = FakeBackend()
        ..on('GET /me/profile', (_) => saved)
        ..on('GET /allergies', (_) => [])
        ..on('PUT /me/profile', (request) => saved = profileJson({'name': 'Demo Patient', 'heightCm': 170.0}));
      await pumpScreen(tester, backend, const ProfileScreen());

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Demo Patient');
      await tester.enterText(find.widgetWithText(TextField, 'Height'), '900');
      await tester.pump();
      expect(find.text('30 to 272 cm'), findsOneWidget);
      await reveal(tester, find.widgetWithText(FilledButton, 'Save profile'));
      expect(filled(tester, 'Save profile').onPressed, isNull);

      await reveal(tester, find.widgetWithText(TextField, 'Height'), -200);
      await tester.enterText(find.widgetWithText(TextField, 'Height'), '170');
      await tester.pump();
      await reveal(tester, find.widgetWithText(FilledButton, 'Save profile'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save profile'));
      await tester.pumpAndSettle();

      final body = backend.bodies('PUT /me/profile').single as Map<String, dynamic>;
      expect(body['name'], 'Demo Patient');
      expect(body['heightCm'], 170.0);
      expect(body['weightKg'], isNull);
      expect(body['bloodGroup'], isNull);
      expect(body.containsKey('email'), isFalse);
      expect(find.text('Profile saved'), findsOneWidget);
    });

    testWidgets('adds and removes an allergy without losing profile text being typed', (tester) async {
      final allergies = <Map<String, dynamic>>[
        {'id': 'a1', 'name': 'Penicillin'},
      ];
      final backend = FakeBackend()
        ..on('GET /me/profile', (_) => profileJson())
        ..on('GET /allergies', (_) => allergies)
        ..on('POST /allergies', (_) {
          allergies.add({'id': 'a2', 'name': 'Ibuprofen'});
          return Reply(201, allergies.last);
        })
        ..on('DELETE /allergies/a1', (_) {
          allergies.removeWhere((a) => a['id'] == 'a1');
          return Reply(204);
        });
      await pumpScreen(tester, backend, const ProfileScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Typed but not saved');

      await reveal(tester, find.widgetWithText(TextField, 'Add an allergy'));
      expect(find.text('Penicillin'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Add an allergy'), 'Ibuprofen');
      await tester.tap(find.byTooltip('Add allergy'));
      await tester.pumpAndSettle();
      expect(backend.bodies('POST /allergies').single, {'name': 'Ibuprofen'});
      // The list refreshed by itself. The new entry pushed the field down, out of view.
      expect(find.text('Ibuprofen', skipOffstage: false), findsOneWidget);
      expect(backend.requests.where((r) => r.method == 'GET' && r.url.path == '/allergies'), hasLength(2));

      await tester.ensureVisible(find.byTooltip('Remove Penicillin', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Penicillin'));
      await tester.pumpAndSettle();
      expect(find.text('Penicillin', skipOffstage: false), findsNothing);

      await reveal(tester, find.widgetWithText(TextField, 'Name'), -200);
      expect(find.text('Typed but not saved'), findsOneWidget);
    });

    testWidgets('calls the emergency contact', (tester) async {
      String? dialled;
      openDialler = (phone) async {
        dialled = phone;
        return true;
      };
      final backend = FakeBackend()
        ..on('GET /me/profile', (_) => profileJson({'emergencyName': 'Demo Contact', 'emergencyPhone': '+91 00000 00900'}))
        ..on('GET /allergies', (_) => []);
      await pumpScreen(tester, backend, const ProfileScreen());
      await reveal(tester, find.widgetWithText(FilledButton, 'Call'));
      await tester.tap(find.widgetWithText(FilledButton, 'Call'));
      await tester.pumpAndSettle();
      expect(dialled, '+91 00000 00900');
    });
  });

  group('Feedback (S4)', () {
    Map<String, dynamic> rated(String? feedback) =>
        {...medicineJson(feedback: feedback), 'condition': 'Sore throat', 'date': '2026-03-12', 'prescriber': 'Dr. A. Mehra'};

    testWidgets('records feedback on the feedback screen and refreshes by itself', (tester) async {
      String? current = 'SIDE_EFFECT';
      final backend = FakeBackend()
        ..on('GET /medicines', (_) => [rated(current)])
        ..on('PUT /medicines/m1/feedback', (_) {
          current = 'WORKED';
          return {};
        });
      await pumpScreen(tester, backend, const FeedbackScreen());
      expect(find.text('Your feedback: Side effect. Not recalled in chat.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Worked'));
      await tester.pumpAndSettle();
      expect(backend.bodies('PUT /medicines/m1/feedback').single, {'value': 'WORKED'});
      expect(find.text('Your feedback: Worked'), findsOneWidget);
    });

    testWidgets('says "No feedback recorded" when there is none', (tester) async {
      final backend = FakeBackend()..on('GET /medicines', (_) => [rated(null)]);
      await pumpScreen(tester, backend, const FeedbackScreen());
      expect(find.text('No feedback recorded'), findsOneWidget);
    });

    testWidgets('feedback can be given on the prescription itself', (tester) async {
      final backend = FakeBackend()
        ..on('GET /prescriptions/p1', (_) => prescriptionJson())
        ..on('PUT /medicines/m1/feedback', (_) => {});
      await pumpScreen(tester, backend, const PrescriptionScreen(prescriptionId: 'p1'));
      await tester.tap(find.widgetWithText(FilterChip, 'Did not work'));
      await tester.pumpAndSettle();
      expect(backend.bodies('PUT /medicines/m1/feedback').single, {'value': 'DID_NOT_WORK'});
    });
  });

  group('Auto refresh (every screen, through Loader)', () {
    testWidgets('an open Timeline updates when a prescription is confirmed elsewhere, without navigating', (tester) async {
      final list = <Map<String, dynamic>>[];
      final backend = FakeBackend()
        ..on('GET /prescriptions', (_) => list)
        ..on('POST /documents/doc1/confirm', (_) {
          list.add(prescriptionJson());
          return Reply(201, prescriptionJson());
        });
      final app = await pumpScreen(tester, backend, const TimelineScreen());
      expect(find.text('No history yet'), findsOneWidget);

      await app.api.confirm('doc1', {});
      await tester.pumpAndSettle();
      expect(find.text('No history yet'), findsNothing);
      expect(find.text('Sore throat'), findsOneWidget);
    });

    testWidgets('pull-to-refresh reloads, also on an empty screen', (tester) async {
      final list = <Map<String, dynamic>>[];
      final backend = FakeBackend()..on('GET /prescriptions', (_) => list);
      await pumpScreen(tester, backend, const TimelineScreen());
      list.add(prescriptionJson());

      await tester.drag(find.text('No history yet'), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.text('Sore throat'), findsOneWidget);
    });

    testWidgets('reloads when the app comes back to the foreground', (tester) async {
      final list = <Map<String, dynamic>>[];
      final backend = FakeBackend()..on('GET /prescriptions', (_) => list);
      await pumpScreen(tester, backend, const TimelineScreen());
      list.add(prescriptionJson());

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Sore throat'), findsOneWidget);
    });

    testWidgets('reading data does not trigger a reload loop', (tester) async {
      final backend = FakeBackend()..on('GET /prescriptions', (_) => []);
      final app = await pumpScreen(tester, backend, const TimelineScreen());
      expect(backend.requests, hasLength(1));
      expect(app.session.revision, 0);
    });
  });

  group('Doctor contacts (S9)', () {
    Map<String, dynamic> card({String? phone = '+91 00000 00101'}) => {
          ...doctorJson(phone: phone),
          'prescriptions': [
            prescriptionJson(),
            prescriptionJson(id: 'p2', condition: 'Headache', date: '2025-08-18'),
          ],
        };

    testWidgets('lists one card per doctor and says details are not verified', (tester) async {
      final backend = FakeBackend()
        ..on('GET /doctors', (_) => [
              doctorJson(),
              {...doctorJson(id: 'd3', phone: null, count: 1), 'name': 'Dr. S. Khan', 'registrationNo': null},
            ]);
      await pumpScreen(tester, backend, const DoctorsScreen());
      expect(find.byType(DoctorCard), findsNWidgets(2));
      expect(find.textContaining('not verified by the app'), findsOneWidget);
      expect(find.text('2 prescriptions'), findsOneWidget);
      expect(find.text('1 prescription'), findsOneWidget);
      expect(find.text('No number on this prescription. Tap to add.'), findsOneWidget);
      expect(find.text('Reg. no. not on prescription'), findsOneWidget);
    });

    testWidgets('shows the card with the not-verified line, emergency line and that doctor\'s prescriptions', (tester) async {
      final backend = FakeBackend()..on('GET /doctors/d1', (_) => card());
      await pumpScreen(tester, backend, const DoctorScreen(doctorId: 'd1'));
      expect(find.text('Dr. A. Mehra'), findsOneWidget);
      expect(find.text('General physician'), findsOneWidget);
      expect(find.text('+91 00000 00101'), findsOneWidget);
      expect(find.text('MH-00000-DEMO'), findsOneWidget);
      expect(find.text('Mon to Sat, 10 am to 1 pm'), findsOneWidget);
      expect(find.text(notVerified), findsOneWidget);
      expect(find.text(emergencyLine), findsOneWidget);
      await reveal(tester, find.text('Headache'));
      final entries = tester.widgetList<TimelineEntry>(find.byType(TimelineEntry, skipOffstage: false)).toList();
      expect(entries.map((e) => e.prescription.condition), containsAll(['Sore throat', 'Headache']));
    });

    testWidgets('opens the dialler with the doctor\'s number', (tester) async {
      String? dialled;
      openDialler = (phone) async {
        dialled = phone;
        return true;
      };
      final backend = FakeBackend()..on('GET /doctors/d1', (_) => card());
      await pumpScreen(tester, backend, const DoctorScreen(doctorId: 'd1'));
      await tester.tap(find.widgetWithText(FilledButton, 'Call'));
      await tester.pumpAndSettle();
      expect(dialled, '+91 00000 00101');
    });

    testWidgets('disables Call when the prescription had no number', (tester) async {
      final backend = FakeBackend()..on('GET /doctors/d1', (_) => card(phone: null));
      await pumpScreen(tester, backend, const DoctorScreen(doctorId: 'd1'));
      expect(find.text('No number on this prescription'), findsOneWidget);
      expect(filled(tester, 'Call').onPressed, isNull);
    });

    testWidgets('previews exactly what is shared and states that medicines are not included', (tester) async {
      const shareBody = 'Dr. A. Mehra\nGeneral physician\nPhone: +91 00000 00101\nAs printed on a prescription. Not verified.';
      String? shared;
      shareText = (text) async => shared = text;
      final backend = FakeBackend()
        ..on('GET /doctors/d1', (_) => card())
        ..on('GET /doctors/d1/share', (_) => {'text': shareBody});
      await pumpScreen(tester, backend, const DoctorScreen(doctorId: 'd1'));

      await tester.tap(find.widgetWithText(FilledButton, 'Share'));
      await tester.pumpAndSettle();
      expect(find.text("Share doctor's contact"), findsOneWidget);
      expect(find.text(shareBody), findsOneWidget);
      expect(find.text(shareOnlyContact), findsOneWidget);
      // Nothing leaves the app until the user presses Share in the sheet.
      expect(shared, isNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Share').last);
      await tester.pumpAndSettle();
      expect(shared, shareBody);
      expect(shared, isNot(contains('Paracetamol')));
    });

    testWidgets('does not share when the user cancels the sheet', (tester) async {
      String? shared;
      shareText = (text) async => shared = text;
      final backend = FakeBackend()
        ..on('GET /doctors/d1', (_) => card())
        ..on('GET /doctors/d1/share', (_) => {'text': 'Dr. A. Mehra'});
      await pumpScreen(tester, backend, const DoctorScreen(doctorId: 'd1'));
      await tester.tap(find.widgetWithText(FilledButton, 'Share'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(shared, isNull);
    });

    testWidgets('edits a card: adds a number, clears a field, and blocks an invalid number', (tester) async {
      final backend = FakeBackend()..on('PATCH /doctors/d1', (_) => doctorJson());
      final doctor = Doctor.fromJson(doctorJson(phone: null));
      await pumpScreen(tester, backend, DoctorEditScreen(doctor: doctor));

      await tester.enterText(find.widgetWithText(TextField, 'Phone (optional)'), 'abc');
      await tester.pump();
      expect(find.text('Check the number'), findsOneWidget);
      expect(filled(tester, 'Save').onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Phone (optional)'), '+91 00000 00103');
      await tester.enterText(find.widgetWithText(TextField, 'Specialty (optional)'), '');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final body = backend.bodies('PATCH /doctors/d1').single as Map<String, dynamic>;
      expect(body['phone'], '+91 00000 00103');
      expect(body['specialty'], isNull);
      expect(body['name'], 'Dr. A. Mehra');
    });

    testWidgets('confirms before deleting and says the prescriptions stay', (tester) async {
      final backend = FakeBackend()..on('DELETE /doctors/d1', (_) => Reply(204));
      await pumpScreen(tester, backend, DoctorEditScreen(doctor: Doctor.fromJson(doctorJson())));

      await tester.tap(find.text('Delete card'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this doctor card?'), findsOneWidget);
      expect(find.textContaining('The 2 prescriptions from this doctor stay in your timeline.'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.requests, isEmpty);

      await tester.tap(find.text('Delete card'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete card'));
      await tester.pumpAndSettle();
      expect(backend.requests.single.method, 'DELETE');
    });

    testWidgets('a prescription has Medicines and Doctor tabs; the Doctor tab links to all their prescriptions', (tester) async {
      final backend = FakeBackend()
        ..on('GET /prescriptions/p1', (_) => prescriptionJson())
        ..on('GET /doctors/d1', (_) => card());
      await pumpScreen(tester, backend, const PrescriptionScreen(prescriptionId: 'p1'));

      expect(find.widgetWithText(Tab, 'Medicines'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Doctor'), findsOneWidget);
      expect(find.text('Sore throat'), findsOneWidget);
      expect(find.text('Stop reminders'), findsOneWidget);

      await tester.tap(find.widgetWithText(Tab, 'Doctor'));
      await tester.pumpAndSettle();
      expect(find.text('Dr. A. Mehra'), findsOneWidget);
      expect(find.text(notVerified), findsOneWidget);

      await tester.tap(find.text('All prescriptions from this doctor'));
      await tester.pumpAndSettle();
      expect(find.text('2 prescriptions, newest first'), findsOneWidget);
    });

    testWidgets('stops a course only after the user confirms', (tester) async {
      final backend = FakeBackend()
        ..on('GET /prescriptions/p1', (_) => prescriptionJson())
        ..on('POST /medicines/m1/schedule/stop', (_) => {});
      final app = await pumpScreen(tester, backend, const PrescriptionScreen(prescriptionId: 'p1'));

      await tester.tap(find.text('Stop reminders'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ask your doctor before stopping'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.bodies('POST /medicines/m1/schedule/stop'), isEmpty);

      await tester.tap(find.text('Stop reminders'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Stop reminders'));
      await tester.pumpAndSettle();
      expect(backend.bodies('POST /medicines/m1/schedule/stop'), hasLength(1));
      expect(app.reminders.syncs, 1);
    });
  });
}
