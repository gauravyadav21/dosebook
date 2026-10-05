import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Base URL comes from `--dart-define=API_BASE_URL=...`; no URLs or keys in code.
/// The Android emulator reaches the host machine at 10.0.2.2.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');

class ApiException implements Exception {
  ApiException(this.status, this.message, [this.body]);

  /// HTTP status, or 0 when the server could not be reached.
  final int status;
  final String message;
  final Json? body;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

/// Thrown by [Api.confirm] when a doctor with the same name already exists and the user must choose (S9).
class DoctorNameMatch implements Exception {
  DoctorNameMatch(this.candidates);

  final List<Doctor> candidates;
}

/// Client for the backend. Holds the session token; every call except sign-in sends it.
class Api {
  Api({http.Client? client, this.baseUrl = apiBaseUrl}) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  String? token;

  /// Called when the server rejects the token, so the app can return to sign-in.
  void Function()? onUnauthorized;

  /// Called after every successful request that changed data, so open screens can refresh themselves.
  void Function()? onChanged;

  static const _timeout = Duration(seconds: 30);

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  /// [changes] is false for requests that are not GET but leave the user's data as it was (sign-in, chat).
  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query, bool? changes}) async {
    final request = http.Request(method, _uri(path, query))..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);
    final result = await _read(() async => http.Response.fromStream(await _client.send(request)));
    if (changes ?? method != 'GET') onChanged?.call();
    return result;
  }

  Future<dynamic> _read(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call().timeout(_timeout);
    } catch (_) {
      throw ApiException(0, 'Could not reach the server. Check your connection and try again.');
    }
    final dynamic decoded = res.body.isEmpty ? null : _tryDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

    final body = decoded is Json ? decoded : null;
    if (res.statusCode == 401 && token != null) onUnauthorized?.call();
    if (res.statusCode == 409 && body?['code'] == 'DOCTOR_NAME_MATCH') {
      throw DoctorNameMatch(
        (body!['candidates'] as List).map((d) => Doctor.fromJson(d as Json)).toList(),
      );
    }
    throw ApiException(res.statusCode, _message(body, res.statusCode), body);
  }

  static dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  static String _message(Json? body, int status) {
    final message = body?['message'];
    if (message is List && message.isNotEmpty) return message.join('\n');
    if (message is String) return message;
    return status == 429 ? 'Too many requests. Wait a minute and try again.' : 'Something went wrong ($status).';
  }

  // --- Auth and first run -------------------------------------------------

  Future<String> register(String email, String password) async =>
      (await _send('POST', '/auth/register', body: {'email': email, 'password': password}, changes: false))['accessToken'] as String;

  Future<String> login(String email, String password) async =>
      (await _send('POST', '/auth/login', body: {'email': email, 'password': password}, changes: false))['accessToken'] as String;

  Future<Me> me() async => Me.fromJson(await _send('GET', '/me') as Json);

  Future<Me> acknowledge(int version) async =>
      Me.fromJson(await _send('PUT', '/me/acknowledgement', body: {'version': version}) as Json);

  // --- Upload, confirm, timeline -------------------------------------------

  Future<UploadedDocument> upload(Uint8List bytes, String fileName) async {
    final request = http.MultipartRequest('POST', _uri('/documents'))
      ..headers.addAll({if (token != null) 'authorization': 'Bearer $token'})
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final json = await _read(() async => http.Response.fromStream(await _client.send(request)));
    // An upload alone changes nothing the user can see; the timeline changes on Confirm.
    return UploadedDocument.fromJson(json as Json);
  }

  /// Bytes of the stored original, for "View original document".
  Future<({Uint8List bytes, String contentType})> documentFile(String documentId) async {
    final http.Response res;
    try {
      res = await _client.get(_uri('/documents/$documentId/file'), headers: _headers).timeout(_timeout);
    } catch (_) {
      throw ApiException(0, 'Could not reach the server. Check your connection and try again.');
    }
    if (res.statusCode != 200) throw ApiException(res.statusCode, 'Could not open the document.');
    return (bytes: res.bodyBytes, contentType: res.headers['content-type'] ?? '');
  }

  Future<Prescription> confirm(String documentId, Json body) async =>
      Prescription.fromJson(await _send('POST', '/documents/$documentId/confirm', body: body) as Json);

  Future<List<Prescription>> prescriptions() async =>
      (await _send('GET', '/prescriptions') as List).map((p) => Prescription.fromJson(p as Json)).toList();

  Future<Prescription> prescription(String id) async =>
      Prescription.fromJson(await _send('GET', '/prescriptions/$id') as Json);

  // --- Feedback and allergies ----------------------------------------------

  Future<List<Medicine>> medicines() async =>
      (await _send('GET', '/medicines') as List).map((m) => Medicine.fromJson(m as Json)).toList();

  Future<void> setFeedback(String medicineId, String? value) =>
      _send('PUT', '/medicines/$medicineId/feedback', body: {'value': value});

  Future<List<Allergy>> allergies() async =>
      (await _send('GET', '/allergies') as List).map((a) => Allergy.fromJson(a as Json)).toList();

  Future<Allergy> addAllergy(String name) async =>
      Allergy.fromJson(await _send('POST', '/allergies', body: {'name': name}) as Json);

  Future<void> deleteAllergy(String id) => _send('DELETE', '/allergies/$id');

  // --- Doses ---------------------------------------------------------------

  Future<List<Dose>> today(String date) async {
    final json = await _send('GET', '/doses/today', query: {'date': date}) as Json;
    return (json['doses'] as List).map((d) => Dose.fromJson(d as Json)).toList();
  }

  Future<void> markDose({
    required String medicineId,
    required String date,
    required String slot,
    required String status,
  }) =>
      _send('POST', '/doses/mark', body: {'medicineId': medicineId, 'date': date, 'slot': slot, 'status': status});

  Future<List<ActiveSchedule>> schedules(String date) async =>
      (await _send('GET', '/doses/schedules', query: {'date': date}) as List)
          .map((s) => ActiveSchedule.fromJson(s as Json))
          .toList();

  Future<void> editSchedule(String medicineId, Json schedule) =>
      _send('PATCH', '/medicines/$medicineId/schedule', body: schedule);

  Future<void> stopCourse(String medicineId, String date) =>
      _send('POST', '/medicines/$medicineId/schedule/stop', body: {'date': date});

  // --- Profile -------------------------------------------------------------

  Future<Profile> profile() async => Profile.fromJson(await _send('GET', '/me/profile') as Json);

  Future<Profile> saveProfile(Profile profile) async =>
      Profile.fromJson(await _send('PUT', '/me/profile', body: profile.toJson()) as Json);

  // --- Notes (free text) and own reminders -----------------------------------

  Future<List<Note>> notes() async =>
      (await _send('GET', '/notes') as List).map((n) => Note.fromJson(n as Json)).toList();

  Future<void> createNote(String text) => _send('POST', '/notes', body: {'text': text});

  Future<void> updateNote(String id, String text) => _send('PATCH', '/notes/$id', body: {'text': text});

  Future<void> deleteNote(String id) => _send('DELETE', '/notes/$id');

  Future<List<Medicine>> ownReminders() async =>
      (await _send('GET', '/own-reminders') as List).map((m) => Medicine.fromJson(m as Json)).toList();

  Future<void> createOwnReminder(Json body) => _send('POST', '/own-reminders', body: body);

  Future<void> updateOwnReminder(String id, Json body) => _send('PATCH', '/own-reminders/$id', body: body);

  Future<void> deleteOwnReminder(String id) => _send('DELETE', '/own-reminders/$id');

  // --- Chat ----------------------------------------------------------------

  Future<ChatAnswer> chat(String message) async =>
      ChatAnswer.fromJson(await _send('POST', '/chat', body: {'message': message}, changes: false) as Json);

  // --- Doctors -------------------------------------------------------------

  Future<List<Doctor>> doctors() async =>
      (await _send('GET', '/doctors') as List).map((d) => Doctor.fromJson(d as Json)).toList();

  Future<Doctor> doctor(String id) async => Doctor.fromJson(await _send('GET', '/doctors/$id') as Json);

  Future<Doctor> updateDoctor(String id, Json body) async =>
      Doctor.fromJson(await _send('PATCH', '/doctors/$id', body: body) as Json);

  Future<void> deleteDoctor(String id) => _send('DELETE', '/doctors/$id');

  Future<String> doctorShareText(String id) async => (await _send('GET', '/doctors/$id/share'))['text'] as String;
}
