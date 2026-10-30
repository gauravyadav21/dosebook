/// Plain data classes for the backend's JSON. No behaviour beyond parsing.
library;

typedef Json = Map<String, dynamic>;

class Me {
  Me({required this.email, required this.ackRequired, required this.ackVersion});

  final String email;
  final bool ackRequired;

  /// Version of the first-run wording to acknowledge.
  final int ackVersion;

  factory Me.fromJson(Json j) => Me(
        email: j['email'] as String,
        ackRequired: j['acknowledgement']['required'] as bool,
        ackVersion: j['acknowledgement']['currentVersion'] as int,
      );
}

class ExtractedMedicine {
  ExtractedMedicine({required this.name, this.dose, this.frequency, this.duration});

  final String name;
  final String? dose;
  final String? frequency;
  final String? duration;

  factory ExtractedMedicine.fromJson(Json j) => ExtractedMedicine(
        name: j['name'] as String,
        dose: j['dose'] as String?,
        frequency: j['frequency'] as String?,
        duration: j['duration'] as String?,
      );
}

/// What was read from an uploaded prescription. Always reviewed by the user before anything is saved.
class Extraction {
  Extraction({this.condition, this.date, this.doctor, required this.medicines});

  final String? condition;
  final String? date;
  final Json? doctor;
  final List<ExtractedMedicine> medicines;

  factory Extraction.fromJson(Json j) => Extraction(
        condition: j['condition'] as String?,
        date: j['date'] as String?,
        doctor: j['doctor'] as Json?,
        medicines: ((j['medicines'] as List?) ?? [])
            .map((m) => ExtractedMedicine.fromJson(m as Json))
            .toList(),
      );
}

class UploadedDocument {
  UploadedDocument({required this.id, required this.fileName, required this.status, this.extraction});

  final String id;
  final String fileName;
  final String status;
  final Extraction? extraction;

  bool get extractionFailed => extraction == null;

  factory UploadedDocument.fromJson(Json j) => UploadedDocument(
        id: j['id'] as String,
        fileName: j['fileName'] as String,
        status: j['status'] as String,
        extraction: j['extraction'] == null ? null : Extraction.fromJson(j['extraction'] as Json),
      );
}

class Doctor {
  Doctor({
    required this.id,
    required this.name,
    this.specialty,
    this.registrationNo,
    this.phone,
    this.availability,
    this.prescriptionCount = 0,
    this.prescriptions = const [],
  });

  final String id;
  final String name;
  final String? specialty;
  final String? registrationNo;
  final String? phone;
  final String? availability;
  final int prescriptionCount;
  final List<Prescription> prescriptions;

  factory Doctor.fromJson(Json j) => Doctor(
        id: j['id'] as String,
        name: j['name'] as String,
        specialty: j['specialty'] as String?,
        registrationNo: j['registrationNo'] as String?,
        phone: j['phone'] as String?,
        availability: j['availability'] as String?,
        prescriptionCount: (j['prescriptionCount'] as int?) ?? 0,
        prescriptions: ((j['prescriptions'] as List?) ?? [])
            .map((p) => Prescription.fromJson(p as Json))
            .toList(),
      );
}

class Schedule {
  Schedule({
    required this.slots,
    required this.times,
    this.food,
    required this.dosesPerDay,
    this.courseDays,
    required this.startDate,
    this.endDate,
    required this.stopped,
  });

  final List<String> slots;
  final List<String> times;
  final String? food;
  final int dosesPerDay;
  final int? courseDays;
  final String startDate;

  /// First date with no dose due. Null for an open-ended own reminder.
  final String? endDate;
  final bool stopped;

  factory Schedule.fromJson(Json j) => Schedule(
        slots: (j['slots'] as List).cast<String>(),
        times: (j['times'] as List).cast<String>(),
        food: j['food'] as String?,
        dosesPerDay: j['dosesPerDay'] as int,
        courseDays: j['courseDays'] as int?,
        startDate: j['startDate'] as String,
        endDate: j['endDate'] as String?,
        stopped: j['stopped'] as bool,
      );
}

class Medicine {
  Medicine({
    required this.id,
    required this.source,
    required this.name,
    this.dose,
    this.frequency,
    this.duration,
    this.feedback,
    this.schedule,
    this.taken,
    this.total,
    this.condition,
    this.date,
    this.prescriber,
  });

  final String id;

  /// PRESCRIPTION or SELF.
  final String source;
  final String name;
  final String? dose;
  final String? frequency;
  final String? duration;

  /// WORKED, DID_NOT_WORK, SIDE_EFFECT or null.
  final String? feedback;
  final Schedule? schedule;
  final int? taken;
  final int? total;

  // Only on the feedback list (GET /medicines).
  final String? condition;
  final String? date;
  final String? prescriber;

  bool get isSelfAdded => source == 'SELF';

  factory Medicine.fromJson(Json j) => Medicine(
        id: j['id'] as String,
        source: j['source'] as String,
        name: j['name'] as String,
        dose: j['dose'] as String?,
        frequency: j['frequency'] as String?,
        duration: j['duration'] as String?,
        feedback: j['feedback'] as String?,
        schedule: j['schedule'] == null ? null : Schedule.fromJson(j['schedule'] as Json),
        taken: j['adherence']?['taken'] as int?,
        total: j['adherence']?['total'] as int?,
        condition: j['condition'] as String?,
        date: j['date'] as String?,
        prescriber: j['prescriber'] as String?,
      );
}

class Prescription {
  Prescription({
    required this.id,
    required this.documentId,
    required this.condition,
    required this.date,
    this.doctor,
    required this.medicines,
    required this.taken,
    required this.total,
  });

  final String id;
  final String documentId;
  final String condition;
  final String date;
  final Doctor? doctor;
  final List<Medicine> medicines;
  final int taken;
  final int total;

  factory Prescription.fromJson(Json j) => Prescription(
        id: j['id'] as String,
        documentId: j['documentId'] as String,
        condition: j['condition'] as String,
        date: j['date'] as String,
        doctor: j['doctor'] == null ? null : Doctor.fromJson(j['doctor'] as Json),
        medicines: (j['medicines'] as List).map((m) => Medicine.fromJson(m as Json)).toList(),
        taken: j['adherence']['taken'] as int,
        total: j['adherence']['total'] as int,
      );
}

class Dose {
  Dose({
    required this.medicineId,
    required this.name,
    this.dose,
    this.food,
    required this.slot,
    required this.group,
    required this.origin,
    required this.status,
    this.markedAt,
  });

  final String medicineId;
  final String name;
  final String? dose;
  final String? food;

  /// Slot name (MORNING...) or a clock time HH:mm for an own reminder.
  final String slot;

  /// Part of the day this dose is listed under.
  final String group;

  /// AS_PRESCRIBED or YOUR_REMINDER.
  final String origin;

  /// DUE, TAKEN or SKIPPED.
  final String status;
  final DateTime? markedAt;

  bool get isOwnReminder => origin == 'YOUR_REMINDER';

  factory Dose.fromJson(Json j) => Dose(
        medicineId: j['medicineId'] as String,
        name: j['name'] as String,
        dose: j['dose'] as String?,
        food: j['food'] as String?,
        slot: j['slot'] as String,
        group: j['group'] as String,
        origin: j['origin'] as String,
        status: j['status'] as String,
        markedAt: j['markedAt'] == null ? null : DateTime.parse(j['markedAt'] as String).toLocal(),
      );
}

/// An active schedule, used to plan local notifications.
class ActiveSchedule {
  ActiveSchedule({
    required this.medicineId,
    required this.name,
    this.dose,
    this.food,
    required this.slots,
    required this.startDate,
    this.endDate,
    required this.origin,
  });

  final String medicineId;
  final String name;
  final String? dose;
  final String? food;
  final List<String> slots;
  final String startDate;
  final String? endDate;
  final String origin;

  factory ActiveSchedule.fromJson(Json j) => ActiveSchedule(
        medicineId: j['medicineId'] as String,
        name: j['name'] as String,
        dose: j['dose'] as String?,
        food: j['food'] as String?,
        slots: (j['slots'] as List).cast<String>(),
        startDate: j['startDate'] as String,
        endDate: j['endDate'] as String?,
        origin: j['origin'] as String,
      );
}

class RecalledMedicine {
  RecalledMedicine({
    required this.medicineId,
    required this.name,
    this.dose,
    this.frequency,
    this.duration,
    this.prescriber,
    this.date,
    this.condition,
    this.feedback,
  });

  final String medicineId;
  final String name;
  final String? dose;
  final String? frequency;
  final String? duration;
  final String? prescriber;
  final String? date;
  final String? condition;

  /// As recorded on the prescription. Chat only displays it.
  final String? feedback;

  factory RecalledMedicine.fromJson(Json j) => RecalledMedicine(
        medicineId: j['medicineId'] as String,
        name: j['name'] as String,
        dose: j['dose'] as String?,
        frequency: j['frequency'] as String?,
        duration: j['duration'] as String?,
        prescriber: j['prescriber'] as String?,
        date: j['date'] as String?,
        condition: j['condition'] as String?,
        feedback: j['feedback'] as String?,
      );
}

class ChatAnswer {
  ChatAnswer({
    required this.kind,
    required this.text,
    required this.medicines,
    this.emergency,
    this.medicineName,
    this.generalUsedFor,
    this.generalStorage,
    this.generalDisclaimer,
    this.allergyMatch = false,
    required this.footer,
  });

  /// RECALL, ESCALATION, NO_HISTORY, MEDICINE_INFO or DECLINED.
  final String kind;
  final String text;
  final List<RecalledMedicine> medicines;
  final String? emergency;

  // MEDICINE_INFO only. The two general facts shown about a medicine, and nothing else.
  final String? medicineName;

  /// What the medicine is usually prescribed for.
  final String? generalUsedFor;

  /// How to keep it. Null when not known.
  final String? generalStorage;
  final String? generalDisclaimer;
  final bool allergyMatch;

  /// The doctor-vs-app line shown under every answer.
  final String footer;

  bool get isEscalation => kind == 'ESCALATION';

  factory ChatAnswer.fromJson(Json j) => ChatAnswer(
        kind: j['kind'] as String,
        text: j['text'] as String,
        medicines: (j['medicines'] as List).map((m) => RecalledMedicine.fromJson(m as Json)).toList(),
        emergency: j['emergency'] as String?,
        medicineName: j['medicineName'] as String?,
        generalUsedFor: j['generalInfo']?['usedFor'] as String?,
        generalStorage: j['generalInfo']?['storage'] as String?,
        generalDisclaimer: j['generalInfo']?['disclaimer'] as String?,
        allergyMatch: (j['allergyMatch'] as bool?) ?? false,
        footer: j['footer'] as String,
      );
}

/// An optional reminder on a note (S15): once on a date, daily, weekly on a weekday, or monthly on a day (1 to 28), at a time.
class NoteReminder {
  const NoteReminder({required this.frequency, required this.time, this.weekday, this.dayOfMonth, this.date});

  /// ONCE, DAILY, WEEKLY or MONTHLY.
  final String frequency;

  /// "HH:mm".
  final String time;

  /// 1 (Monday) to 7 (Sunday); weekly only.
  final int? weekday;

  /// 1 to 28; monthly only.
  final int? dayOfMonth;

  /// "YYYY-MM-DD"; one-time only.
  final String? date;

  factory NoteReminder.fromJson(Json j) => NoteReminder(
        frequency: j['frequency'] as String,
        time: j['time'] as String,
        weekday: j['weekday'] as int?,
        dayOfMonth: j['dayOfMonth'] as int?,
        date: j['date'] as String?,
      );

  Json toJson() => {
        'frequency': frequency,
        'time': time,
        if (frequency == 'WEEKLY') 'weekday': weekday,
        if (frequency == 'MONTHLY') 'dayOfMonth': dayOfMonth,
        if (frequency == 'ONCE') 'date': date,
      };
}

/// A free-text note (S7), with an optional reminder (S15).
class Note {
  Note({required this.id, required this.text, required this.updatedAt, this.reminder});

  final String id;
  final String text;
  final DateTime updatedAt;
  final NoteReminder? reminder;

  factory Note.fromJson(Json j) => Note(
        id: j['id'] as String,
        text: j['text'] as String,
        updatedAt: DateTime.parse(j['updatedAt'] as String).toLocal(),
        reminder: j['reminder'] == null ? null : NoteReminder.fromJson(j['reminder'] as Json),
      );
}

/// The user's own record of themselves (S10). Every field is optional.
class Profile {
  Profile({
    this.email = '',
    this.name,
    this.dateOfBirth,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.bloodGroup,
    this.emergencyName,
    this.emergencyPhone,
    this.conditions,
  });

  final String email;
  final String? name;
  final String? dateOfBirth;

  /// FEMALE, MALE or OTHER.
  final String? sex;
  final double? heightCm;
  final double? weightKg;
  final String? bloodGroup;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? conditions;

  factory Profile.fromJson(Json j) => Profile(
        email: j['email'] as String,
        name: j['name'] as String?,
        dateOfBirth: j['dateOfBirth'] as String?,
        sex: j['sex'] as String?,
        heightCm: (j['heightCm'] as num?)?.toDouble(),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        bloodGroup: j['bloodGroup'] as String?,
        emergencyName: j['emergencyName'] as String?,
        emergencyPhone: j['emergencyPhone'] as String?,
        conditions: j['conditions'] as String?,
      );

  /// Body for PUT /me/profile: every field is sent, null clears it.
  Json toJson() => {
        'name': name,
        'dateOfBirth': dateOfBirth,
        'sex': sex,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'bloodGroup': bloodGroup,
        'emergencyName': emergencyName,
        'emergencyPhone': emergencyPhone,
        'conditions': conditions,
      };
}

class Allergy {
  Allergy({required this.id, required this.name});

  final String id;
  final String name;

  factory Allergy.fromJson(Json j) => Allergy(id: j['id'] as String, name: j['name'] as String);
}
