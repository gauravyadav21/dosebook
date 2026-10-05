import 'package:flutter_test/flutter_test.dart';
import 'package:dosebook/api/api.dart';
import 'package:dosebook/api/models.dart';
import 'package:dosebook/app/format.dart';
import 'package:dosebook/features/upload/schedule_editor.dart';
import 'package:dosebook/reminders/reminder_plan.dart';

import 'support/fake_backend.dart';

ActiveSchedule schedule({
  String id = 'm1',
  List<String> slots = const ['MORNING', 'NIGHT'],
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
        DateTime(2026, 10, 4, 21, 0),
        DateTime(2026, 10, 4, 21, 30),
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
      expect(plan.map((r) => r.at.hour), [21, 21]);
    });

    test('leaves out times already past, but keeps a follow-up that is still ahead', () {
      final plan = planReminders(schedules: [schedule()], now: DateTime(2026, 10, 4, 8, 10), days: 1);
      expect(plan.map((r) => r.at), [
        DateTime(2026, 10, 4, 8, 30),
        DateTime(2026, 10, 4, 21, 0),
        DateTime(2026, 10, 4, 21, 30),
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
        schedules: [schedule(), schedule(id: 'm2', slots: ['MORNING', 'NOON', 'EVENING', 'NIGHT'])],
        now: morning,
      );
      expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
    });

    test('returns the nearest reminders first and caps the total', () {
      final many = [for (var i = 0; i < 20; i++) schedule(id: 'm$i', slots: ['MORNING', 'NOON', 'EVENING', 'NIGHT'])];
      final plan = planReminders(schedules: many, now: morning, days: 3);
      expect(plan, hasLength(maxPlanned));
      expect(plan.first.at, DateTime(2026, 10, 4, 8, 0));
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].at.isBefore(plan[i - 1].at), isFalse);
      }
    });

    test('plans nothing without schedules', () {
      expect(planReminders(schedules: [], now: morning), isEmpty);
    });
  });

  group('ScheduleDraft (S2: Confirm stays disabled until complete)', () {
    test('is incomplete until slots, food timing and a valid course length are set', () {
      final draft = ScheduleDraft();
      expect(draft.complete, isFalse);
      expect(draft.missing, contains('times of day'));
      draft.slots.addAll(['NIGHT', 'MORNING']);
      draft.food = 'AFTER_FOOD';
      expect(draft.complete, isFalse);
      draft.courseDays.text = '5';
      expect(draft.complete, isTrue);
      expect(draft.missing, isEmpty);
    });

    test('rejects a course length of zero, over the limit, or not a number', () {
      final draft = ScheduleDraft(slots: {'NIGHT'}, food: 'AFTER_FOOD');
      for (final bad in ['0', '-3', '366', 'ten', '']) {
        draft.courseDays.text = bad;
        expect(draft.complete, isFalse, reason: bad);
      }
    });

    test('sends slots in day order with doses per day equal to the number of slots', () {
      final draft = ScheduleDraft(slots: {'NIGHT', 'MORNING'}, food: 'BEFORE_FOOD', courseDays: '7');
      expect(draft.toJson(startDate: '2026-10-04'), {
        'slots': ['MORNING', 'NIGHT'],
        'food': 'BEFORE_FOOD',
        'dosesPerDay': 2,
        'courseDays': 7,
        'startDate': '2026-10-04',
      });
      expect(draft.toJson().containsKey('startDate'), isFalse);
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
      expect(slotLabel('NOON'), 'Noon');
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
      expect(list.single.medicines.single.schedule!.slots, ['MORNING', 'NOON', 'NIGHT']);
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
