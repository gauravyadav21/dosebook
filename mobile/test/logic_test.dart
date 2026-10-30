import 'package:flutter_test/flutter_test.dart';
import 'package:dosebook/api/api.dart';
import 'package:dosebook/api/models.dart';
import 'package:dosebook/app/format.dart';
import 'package:dosebook/app/wording.dart';
import 'package:dosebook/features/upload/schedule_editor.dart';
import 'package:dosebook/reminders/reminder_plan.dart';

import 'support/fake_backend.dart';

ActiveSchedule schedule({
  String id = 'm1',
  List<String> slots = const ['MORNING', 'DINNER'],
  String start = '2026-10-04',
  String? end = '2026-10-09',
  String origin = 'AS_PRESCRIBED',
}) =>
    ActiveSchedule(
      medicineId: id,
      name: 'Paracetamol',
      dose: '500 mg',
      food: 'AFTER_FOOD',
      slots: slots,
      startDate: start,
      endDate: end,
      origin: origin,
    );

void main() {
  group('planReminders (S6)', () {
    final morning = DateTime(2026, 10, 4, 7, 0);

    test('plans a reminder at each slot and one follow-up 30 minutes later', () {
      final plan = planReminders(schedules: [schedule()], now: morning, days: 1);
      expect(plan.map((r) => r.at), [
        DateTime(2026, 10, 4, 8, 0),
        DateTime(2026, 10, 4, 8, 30),
        DateTime(2026, 10, 4, 20, 0),
        DateTime(2026, 10, 4, 20, 30),
      ]);
      expect(plan.map((r) => r.followUp), [false, true, false, true]);
      expect(plan.first.title, 'Time for Paracetamol');
      expect(plan[1].title, 'Still due: Paracetamol');
      expect(plan.first.body, '500 mg · after food · as prescribed');
    });

    test('plans nothing for a dose already marked taken or skipped', () {
      final plan = planReminders(
        schedules: [schedule()],
        now: morning,
        days: 1,
        marked: {doseKey('m1', '2026-10-04', 'MORNING')},
      );
      expect(plan.map((r) => r.at.hour), [20, 20]);
    });

    test('leaves out times already past, but keeps a follow-up that is still ahead', () {
      final plan = planReminders(schedules: [schedule()], now: DateTime(2026, 10, 4, 8, 10), days: 1);
      expect(plan.map((r) => r.at), [
        DateTime(2026, 10, 4, 8, 30),
        DateTime(2026, 10, 4, 20, 0),
        DateTime(2026, 10, 4, 20, 30),
      ]);
    });

    test('stops when the course length is reached', () {
      final plan = planReminders(schedules: [schedule(end: '2026-10-05')], now: morning, days: 3);
      expect(plan.every((r) => r.at.day == 4), isTrue);
      expect(plan, hasLength(4));
    });

    test('does not start before the course start date', () {
      final plan = planReminders(schedules: [schedule(start: '2026-10-05')], now: morning, days: 2);
      expect(plan.every((r) => r.at.day == 5), isTrue);
    });

    test('uses the clock time of an own reminder and labels it as the user\'s own', () {
      final plan = planReminders(
        schedules: [schedule(slots: ['21:30'], end: null, origin: 'YOUR_REMINDER')],
        now: morning,
        days: 1,
      );
      expect(plan.first.at, DateTime(2026, 10, 4, 21, 30));
      expect(plan.first.body, contains('your reminder'));
      expect(plan.first.body, isNot(contains('prescribed')));
    });

    test('gives every planned notification a different id', () {
      final plan = planReminders(
        schedules: [schedule(), schedule(id: 'm2', slots: ['MORNING', 'LUNCH', 'DINNER'])],
        now: morning,
      );
      expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
    });

    test('returns the nearest reminders first and caps the total', () {
      final many = [for (var i = 0; i < 20; i++) schedule(id: 'm$i', slots: ['MORNING', 'LUNCH', 'DINNER'])];
      final plan = planReminders(schedules: many, now: morning, days: 3);
      expect(plan, hasLength(maxPlanned));
      expect(plan.first.at, DateTime(2026, 10, 4, 8, 0));
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].at.isBefore(plan[i - 1].at), isFalse);
      }
    });

    test('skips a time it cannot read instead of failing the whole plan', () {
      // Found by the Gemini review (5 Oct 2026). The server only stores HH:mm, but one bad row must not stop every reminder.
      final plan = planReminders(
        schedules: [
          schedule(id: 'bad', slots: ['soon', '7', '25:00', '08:99', ''], end: null),
          schedule(id: 'good', slots: ['DINNER'], end: null),
        ],
        now: morning,
        days: 1,
      );
      expect(plan.map((r) => r.at), [DateTime(2026, 10, 4, 20, 0), DateTime(2026, 10, 4, 20, 30)]);
    });

    test('plans a chosen time instead of the default (S14)', () {
      final plan = planReminders(schedules: [schedule(slots: ['07:30', 'DINNER'])], now: morning, days: 1);
      expect(plan.map((r) => r.at), [
        DateTime(2026, 10, 4, 7, 30),
        DateTime(2026, 10, 4, 8, 0),
        DateTime(2026, 10, 4, 20, 0),
        DateTime(2026, 10, 4, 20, 30),
      ]);
    });

    test('plans nothing without schedules', () {
      expect(planReminders(schedules: [], now: morning), isEmpty);
    });
  });

  group('ScheduleDraft (S2: Confirm stays disabled until complete)', () {
    test('is incomplete until times, food timing and a valid course length are set', () {
      final draft = ScheduleDraft();
      expect(draft.complete, isFalse);
      expect(draft.missing, contains('times of day'));
      draft.slots.addAll(['DINNER', 'MORNING']);
      draft.syncDoses();
      draft.food = 'AFTER_FOOD';
      expect(draft.complete, isFalse);
      draft.courseDays.text = '5';
      expect(draft.complete, isTrue);
      expect(draft.missing, isEmpty);
    });

    test('rejects a course length of zero, over the limit, or not a number', () {
      final draft = ScheduleDraft(slots: {'DINNER'}, food: 'AFTER_FOOD', dosesPerDay: '1');
      for (final bad in ['0', '-3', '366', 'ten', '']) {
        draft.courseDays.text = bad;
        expect(draft.complete, isFalse, reason: bad);
      }
    });

    test('sends the times in day order with the doses per day that was entered', () {
      final draft = ScheduleDraft(slots: {'DINNER', 'MORNING'}, food: 'BEFORE_FOOD', courseDays: '7', dosesPerDay: '2');
      expect(draft.toJson(startDate: '2026-10-04'), {
        'slots': ['MORNING', 'DINNER'],
        'times': <String>[],
        'food': 'BEFORE_FOOD',
        'dosesPerDay': 2,
        'courseDays': 7,
        'startDate': '2026-10-04',
      });
      expect(draft.toJson().containsKey('startDate'), isFalse);
    });
  });

  group('ScheduleDraft times and doses per day (S14)', () {
    ScheduleDraft draft({
      Set<String> slots = const {},
      Map<String, String> custom = const {},
      List<String> extra = const [],
      String doses = '',
    }) =>
        ScheduleDraft(
          slots: {...slots},
          customTimes: {...custom},
          extraTimes: [...extra],
          food: 'AFTER_FOOD',
          courseDays: '5',
          dosesPerDay: doses,
        );

    test('a slot with no chosen time is taken at its default time', () {
      final d = draft(slots: {'MORNING', 'LUNCH', 'DINNER'}, doses: '3');
      expect([for (final s in slotOrder) d.timeOf(s)], ['08:00', '13:00', '20:00']);
      expect(d.toJson()['times'], isEmpty);
      expect(d.complete, isTrue);
    });

    test('a chosen time is sent as a time, the other slots stay named', () {
      final d = draft(slots: {'MORNING', 'DINNER'}, custom: {'MORNING': '07:30'}, doses: '2');
      expect(d.toJson()['slots'], ['DINNER']);
      expect(d.toJson()['times'], ['07:30']);
      expect(d.toJson()['dosesPerDay'], 2);
    });

    test('doses per day follows the times chosen until the user types a number', () {
      final d = ScheduleDraft();
      d.slots.add('MORNING');
      d.syncDoses();
      expect(d.dosesPerDay.text, '1');
      d.extraTimes.add('14:00');
      d.syncDoses();
      expect(d.dosesPerDay.text, '2');

      d.dosesPerDay.text = '5';
      d.dosesTouched = true;
      d.slots.add('DINNER');
      d.syncDoses();
      expect(d.dosesPerDay.text, '5', reason: 'the user\'s own number is kept');

      d.dosesPerDay.text = '';
      d.dosesTouched = false;
      d.syncDoses();
      expect(d.dosesPerDay.text, '3');
    });

    test('five or ten doses a day: the number can be typed, and the times must match it', () {
      final d = draft(slots: {'MORNING'}, extra: ['10:00', '12:00'], doses: '5');
      expect(d.complete, isFalse);
      expect(d.missing, contains('add 2 more times'));
      d.extraTimes.addAll(['14:00', '16:00']);
      expect(d.complete, isTrue);
      expect(d.toJson()['times'], ['10:00', '12:00', '14:00', '16:00']);
      expect(d.toJson()['dosesPerDay'], 5);

      final ten = draft(extra: [for (var h = 6; h < 16; h++) '${h.toString().padLeft(2, '0')}:00'], doses: '10');
      expect(ten.complete, isTrue);
    });

    test('too many times for the number typed, a number out of range, or a duplicate time block Confirm', () {
      final many = draft(slots: {'MORNING', 'LUNCH', 'DINNER'}, doses: '2');
      expect(many.complete, isFalse);
      expect(many.missing, contains('remove 1 time'));

      expect(draft(slots: {'MORNING'}, doses: '0').complete, isFalse);
      expect(draft(slots: {'MORNING'}, doses: '13').complete, isFalse);
      expect(draft(slots: {'MORNING'}, doses: 'two').complete, isFalse);

      final same = draft(slots: {'MORNING'}, extra: ['08:00'], doses: '2');
      expect(same.duplicate, isTrue);
      expect(same.complete, isFalse);
      expect(same.missing, contains('same time'));
    });

    test('reading a saved schedule gives each time a chip when it is free, and keeps the rest as extra doses', () {
      final d = ScheduleDraft.from(Schedule(
        slots: const ['DINNER'],
        times: const ['07:30', '09:00', '13:15'],
        food: 'AFTER_FOOD',
        dosesPerDay: 4,
        courseDays: 5,
        startDate: '2026-10-04',
        stopped: false,
      ));
      expect(d.slots, {'DINNER', 'MORNING', 'LUNCH'});
      expect(d.customTimes, {'MORNING': '07:30', 'LUNCH': '13:15'});
      expect(d.extraTimes, ['09:00']);
      expect(d.dosesPerDay.text, '4');
      expect(d.complete, isTrue);
      expect(d.toJson()['times'], ['07:30', '09:00', '13:15']);
    });

    test('groups a clock time by the part of the day, like the server', () {
      expect([for (final t in ['06:00', '10:59', '11:00', '15:59', '16:00', '23:30']) slotGroupOf(t)],
          ['MORNING', 'MORNING', 'LUNCH', 'LUNCH', 'DINNER', 'DINNER']);
    });
  });

  group('planNoteReminders (S15)', () {
    // Sunday 4 October 2026, 07:00.
    final now = DateTime(2026, 10, 4, 7, 0);

    Note note(String id, String text, NoteReminder? reminder) =>
        Note(id: id, text: text, updatedAt: DateTime(2026, 10, 1), reminder: reminder);

    PlannedNoteReminder only(NoteReminder r, {String text = 'Drink water'}) =>
        planNoteReminders([note('n1', text, r)], now).single;

    test('plans nothing for a note without a reminder', () {
      expect(planNoteReminders([note('n1', 'x', null)], now), isEmpty);
      expect(planNoteReminders([], now), isEmpty);
    });

    test('one time: that date and time if still ahead, otherwise nothing is planned', () {
      final ahead = only(const NoteReminder(frequency: 'ONCE', time: '09:00', date: '2026-10-12'));
      expect(ahead.firstAt, DateTime(2026, 10, 12, 9, 0));
      expect(ahead.repeat, NoteRepeat.once);
      expect(only(const NoteReminder(frequency: 'ONCE', time: '09:00', date: '2026-10-04')).firstAt, DateTime(2026, 10, 4, 9, 0));

      for (final past in [
        const NoteReminder(frequency: 'ONCE', time: '06:59', date: '2026-10-04'),
        const NoteReminder(frequency: 'ONCE', time: '07:00', date: '2026-10-04'),
        const NoteReminder(frequency: 'ONCE', time: '09:00', date: '2026-10-03'),
        const NoteReminder(frequency: 'ONCE', time: '09:00'),
        const NoteReminder(frequency: 'ONCE', time: '09:00', date: 'next week'),
      ]) {
        expect(planNoteReminders([note('n1', 'x', past)], now), isEmpty, reason: '${past.date} ${past.time}');
      }
    });

    test('daily: today if the time is still ahead, otherwise tomorrow', () {
      final ahead = only(const NoteReminder(frequency: 'DAILY', time: '09:00'));
      expect(ahead.firstAt, DateTime(2026, 10, 4, 9, 0));
      expect(ahead.repeat, NoteRepeat.daily);
      expect(only(const NoteReminder(frequency: 'DAILY', time: '06:00')).firstAt, DateTime(2026, 10, 5, 6, 0));
      expect(only(const NoteReminder(frequency: 'DAILY', time: '07:00')).firstAt, DateTime(2026, 10, 5, 7, 0), reason: 'not after now');
    });

    test('weekly: the next chosen weekday (1 is Monday)', () {
      final monday = only(const NoteReminder(frequency: 'WEEKLY', time: '07:30', weekday: 1));
      expect(monday.firstAt, DateTime(2026, 10, 5, 7, 30));
      expect(monday.repeat, NoteRepeat.weekly);
      expect(only(const NoteReminder(frequency: 'WEEKLY', time: '09:00', weekday: 7)).firstAt, DateTime(2026, 10, 4, 9, 0));
      expect(only(const NoteReminder(frequency: 'WEEKLY', time: '06:00', weekday: 7)).firstAt, DateTime(2026, 10, 11, 6, 0));
      expect(only(const NoteReminder(frequency: 'WEEKLY', time: '09:00', weekday: 3)).firstAt, DateTime(2026, 10, 7, 9, 0));
    });

    test('monthly: this month if the day is still ahead, otherwise next month', () {
      final fifth = only(const NoteReminder(frequency: 'MONTHLY', time: '08:00', dayOfMonth: 5));
      expect(fifth.firstAt, DateTime(2026, 10, 5, 8, 0));
      expect(fifth.repeat, NoteRepeat.monthly);
      expect(only(const NoteReminder(frequency: 'MONTHLY', time: '09:00', dayOfMonth: 4)).firstAt, DateTime(2026, 10, 4, 9, 0));
      expect(only(const NoteReminder(frequency: 'MONTHLY', time: '06:00', dayOfMonth: 4)).firstAt, DateTime(2026, 11, 4, 6, 0));
      expect(only(const NoteReminder(frequency: 'MONTHLY', time: '06:00', dayOfMonth: 28)).firstAt, DateTime(2026, 10, 28, 6, 0));
    });

    test('monthly in December rolls over to January', () {
      final december = DateTime(2026, 12, 20, 10, 0);
      final plan = planNoteReminders(
        [note('n1', 'x', const NoteReminder(frequency: 'MONTHLY', time: '09:00', dayOfMonth: 3))],
        december,
      );
      expect(plan.single.firstAt, DateTime(2027, 1, 3, 9, 0));
    });

    test('shows the note\'s first line, shortened, under a fixed title', () {
      const daily = NoteReminder(frequency: 'DAILY', time: '09:00');
      expect(only(daily, text: '\n  Call the clinic\nabout the cough').body, 'Call the clinic');
      expect(only(daily, text: 'Call the clinic').title, 'Note reminder');
      final long = only(daily, text: 'x' * 200).body;
      expect(long.length, lessThanOrEqualTo(noteReminderBodyLength));
      expect(long, endsWith('…'));
    });

    test('gives every note its own stable id', () {
      const daily = NoteReminder(frequency: 'DAILY', time: '09:00');
      final a = planNoteReminders([note('n1', 'a', daily), note('n2', 'b', daily)], now);
      final b = planNoteReminders([note('n1', 'a', daily), note('n2', 'b', daily)], now);
      expect(a.map((r) => r.id).toSet(), hasLength(2));
      expect(a.map((r) => r.id), b.map((r) => r.id));
    });

    test('skips a reminder it cannot read instead of failing the rest', () {
      final plan = planNoteReminders([
        note('bad', 'x', const NoteReminder(frequency: 'DAILY', time: '25:99')),
        note('weekly-no-day', 'x', const NoteReminder(frequency: 'WEEKLY', time: '09:00')),
        note('good', 'x', const NoteReminder(frequency: 'DAILY', time: '09:00')),
      ], now);
      expect(plan, hasLength(1));
    });
  });

  group('reminderWords (S15)', () {
    test('says the schedule in plain words', () {
      expect(reminderWords('DAILY', '09:00'), 'Daily at 9:00 am');
      expect(reminderWords('WEEKLY', '07:30', weekday: 1), 'Weekly on Monday at 7:30 am');
      expect(reminderWords('WEEKLY', '19:00', weekday: 7), 'Weekly on Sunday at 7:00 pm');
      expect(reminderWords('MONTHLY', '08:00', dayOfMonth: 5), 'Monthly on day 5 at 8:00 am');
      expect(reminderWords('ONCE', '14:30', date: '2026-10-12'), 'Once on 12 Oct 2026 at 2:30 pm');
    });
  });

  group('format', () {
    test('dates', () {
      expect(isoDate(DateTime(2026, 3, 5)), '2026-03-05');
      expect(prettyDate('2026-03-12'), '12 Mar 2026');
      expect(prettyDate('not a date'), 'not a date');
      expect(longDay(DateTime(2026, 10, 4)), 'Sunday 4 October');
    });
    test('clock', () {
      expect(clock(8, 5), '8:05 am');
      expect(clock(0, 0), '12:00 am');
      expect(clock(12, 30), '12:30 pm');
      expect(clockFromText('21:30'), '9:30 pm');
    });
    test('labels', () {
      expect(slotLabel('LUNCH'), 'Lunch');
      expect(slotLabel('07:15'), '7:15 am');
      expect(foodLabel('AFTER_FOOD'), 'after food');
      expect(foodLabel(null), isNull);
      expect(feedbackLabel('DID_NOT_WORK'), 'Did not work');
      expect(dotted(['500 mg', null, '', '5 days']), '500 mg · 5 days');
    });
  });

  group('Api', () {
    test('sends the token and parses the timeline', () async {
      final backend = FakeBackend()..on('GET /prescriptions', (_) => [prescriptionJson()]);
      final api = Api(client: backend.client, baseUrl: 'http://test')..token = 'abc';
      final list = await api.prescriptions();
      expect(list.single.condition, 'Sore throat');
      expect(list.single.doctor!.registrationNo, 'MH-00000-DEMO');
      expect(list.single.medicines.single.schedule!.slots, ['MORNING', 'LUNCH', 'DINNER']);
      expect(backend.requests.single.headers['authorization'], 'Bearer abc');
    });

    test('turns a validation error into a readable message', () async {
      final backend = FakeBackend()
        ..on('POST /allergies', (_) => Reply(400, {'message': ['name should not be empty'], 'statusCode': 400}));
      final api = Api(client: backend.client, baseUrl: 'http://test');
      await expectLater(
        api.addAllergy(''),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400).having((e) => e.message, 'message', 'name should not be empty')),
      );
    });

    test('reports the "same doctor?" answer as DoctorNameMatch with the candidates', () async {
      final backend = FakeBackend()
        ..on('POST /documents/doc1/confirm', (_) => Reply(409, {'code': 'DOCTOR_NAME_MATCH', 'message': 'x', 'candidates': [doctorJson()]}));
      final api = Api(client: backend.client, baseUrl: 'http://test');
      await expectLater(
        api.confirm('doc1', {}),
        throwsA(isA<DoctorNameMatch>().having((e) => e.candidates.single.name, 'candidate', 'Dr. A. Mehra')),
      );
    });

    test('signals an expired session so the app can return to sign-in', () async {
      final backend = FakeBackend()..on('GET /me', (_) => Reply(401, {'message': 'Session expired or invalid. Sign in again.'}));
      var signedOut = false;
      final api = Api(client: backend.client, baseUrl: 'http://test')
        ..token = 'old'
        ..onUnauthorized = () => signedOut = true;
      await expectLater(api.me(), throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', true)));
      expect(signedOut, isTrue);
    });

    test('does not treat a wrong password as an expired session', () async {
      final backend = FakeBackend()..on('POST /auth/login', (_) => Reply(401, {'message': 'Email or password is incorrect'}));
      var signedOut = false;
      final api = Api(client: backend.client, baseUrl: 'http://test')..onUnauthorized = () => signedOut = true;
      await expectLater(api.login('a@example.com', 'wrong-password'), throwsA(isA<ApiException>()));
      expect(signedOut, isFalse);
    });

    test('says the demo server may be waking when it cannot be reached in the demo build (S13)', () async {
      final backend = FakeBackend()..on('GET /notes', (_) => throw Exception('socket closed'));
      final api = Api(client: backend.client, baseUrl: 'http://test', demo: true);
      await expectLater(
        api.notes(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', allOf(contains('Could not reach the server'), contains(demoServerWaking)))),
      );
      final plain = Api(client: backend.client, baseUrl: 'http://test', demo: false);
      await expectLater(plain.notes(), throwsA(isA<ApiException>().having((e) => e.message, 'message', isNot(contains('demo')))));
    });

    test('reports a network failure in plain words', () async {
      final backend = FakeBackend()..on('GET /notes', (_) => throw Exception('socket closed'));
      final api = Api(client: backend.client, baseUrl: 'http://test');
      await expectLater(
        api.notes(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 0).having((e) => e.message, 'message', contains('Could not reach the server'))),
      );
    });
  });
}
