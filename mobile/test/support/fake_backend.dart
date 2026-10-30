import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dosebook/api/api.dart';
import 'package:dosebook/api/models.dart';
import 'package:dosebook/app/app_scope.dart';
import 'package:dosebook/reminders/reminders.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dosebook/app/theme.dart';
import 'package:dosebook/widgets/dismiss_keyboard.dart';

typedef Handler = Object? Function(http.Request request);

/// Reply with a status other than 200.
class Reply {
  Reply(this.status, [this.body]);

  final int status;
  final Object? body;
}

/// In-memory stand-in for the backend. Tests register a handler per "METHOD /path" and inspect [requests].
class FakeBackend {
  // Today always asks for the user's own reminders; most tests have none.
  final Map<String, Handler> _handlers = {'GET /own-reminders': (_) => []};
  final List<http.Request> requests = [];

  void on(String route, Handler handler) => _handlers[route] = handler;

  /// JSON bodies sent to [route], in order.
  List<dynamic> bodies(String route) => [
        for (final r in requests)
          if ('${r.method} ${r.url.path}' == route) r.body.isEmpty ? null : jsonDecode(r.body),
      ];

  http.Client get client => MockClient((request) async {
        requests.add(request);
        final handler = _handlers['${request.method} ${request.url.path}'];
        if (handler == null) {
          return http.Response(jsonEncode({'message': 'No fake for ${request.method} ${request.url.path}'}), 404);
        }
        final result = handler(request);
        final headers = {'content-type': 'application/json; charset=utf-8'};
        if (result is Reply) {
          return http.Response.bytes(utf8.encode(result.body == null ? '' : jsonEncode(result.body)), result.status,
              headers: headers);
        }
        return http.Response.bytes(utf8.encode(result == null ? '' : jsonEncode(result)), 200, headers: headers);
      });
}

/// Counts reminder syncs instead of touching the notification plugin.
class RecordingReminders implements Reminders {
  int syncs = 0;
  int clears = 0;

  @override
  Future<void> sync(Api api) async => syncs++;

  @override
  Future<void> clear() async => clears++;
}

class TestApp {
  TestApp(this.backend, {bool signedIn = true, bool intro = false})
      : reminders = RecordingReminders(),
        api = Api(client: backend.client, baseUrl: 'http://test') {
    if (signedIn) api.token = 'test-token';
    session = Session(api, reminders: reminders)
      ..loading = false
      // Most tests start past the intro pages (S12). As in Session.restore, a signed-in start never shows them.
      ..introDone = !intro || signedIn;
    // A signed-in test user has already accepted the first-run acknowledgement.
    if (signedIn) {
      session.me = Me.fromJson({
        'id': 'u1',
        'email': 'demo.patient@example.com',
        'acknowledgement': {'currentVersion': 1, 'acknowledgedVersion': 1, 'required': false},
      });
    }
  }

  final FakeBackend backend;
  final RecordingReminders reminders;
  final Api api;
  late final Session session;

  Widget wrap(Widget child) => AppScope(
        session: session,
        child: MaterialApp(
          theme: appTheme(Brightness.light),
          builder: dismissKeyboardBuilder,
          home: child,
        ),
      );
}

/// Pumps [child] inside the app scope on a phone-sized screen and waits for loading to finish.
Future<TestApp> pumpScreen(WidgetTester tester, FakeBackend backend, Widget child, {bool signedIn = true}) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = TestApp(backend, signedIn: signedIn);
  await tester.pumpWidget(app.wrap(child));
  await tester.pumpAndSettle();
  return app;
}

// ---- Fake data (all invented) ------------------------------------------------

Map<String, dynamic> doctorJson({String id = 'd1', String? phone = '+91 00000 00101', int count = 2}) => {
      'id': id,
      'name': 'Dr. A. Mehra',
      'specialty': 'General physician',
      'registrationNo': 'MH-00000-DEMO',
      'phone': phone,
      'availability': 'Mon to Sat, 10 am to 1 pm',
      'prescriptionCount': count,
    };

Map<String, dynamic> medicineJson({
  String id = 'm1',
  String name = 'Paracetamol',
  String source = 'PRESCRIPTION',
  String? feedback,
  Map<String, dynamic>? schedule,
}) =>
    {
      'id': id,
      'source': source,
      'name': name,
      'dose': '500 mg, 1 tablet',
      'frequency': '3 times a day',
      'duration': '5 days',
      'feedback': feedback,
      'schedule': schedule,
      'adherence': schedule == null ? null : {'taken': 2, 'total': 15},
    };

Map<String, dynamic> scheduleJson({String endDate = '2999-01-01', bool stopped = false}) => {
      'slots': ['MORNING', 'LUNCH', 'DINNER'],
      'times': <String>[],
      'food': 'AFTER_FOOD',
      'dosesPerDay': 3,
      'courseDays': 5,
      'startDate': '2026-10-01',
      'endDate': endDate,
      'stopped': stopped,
    };

Map<String, dynamic> prescriptionJson({String id = 'p1', String condition = 'Sore throat', String date = '2026-03-12'}) => {
      'id': id,
      'documentId': 'doc1',
      'condition': condition,
      'date': date,
      'doctor': doctorJson(),
      'medicines': [medicineJson(schedule: scheduleJson())],
      'adherence': {'taken': 2, 'total': 15},
    };

Map<String, dynamic> doseJson({
  String medicineId = 'm1',
  String name = 'Paracetamol',
  String slot = 'MORNING',
  String? group,
  String origin = 'AS_PRESCRIBED',
  String status = 'DUE',
  String? food = 'AFTER_FOOD',
}) =>
    {
      'medicineId': medicineId,
      'name': name,
      'dose': '500 mg, 1 tablet',
      'food': food,
      'slot': slot,
      'group': group ?? slot,
      'origin': origin,
      'status': status,
      'markedAt': status == 'DUE' ? null : '2026-10-04T02:35:00.000Z',
    };
