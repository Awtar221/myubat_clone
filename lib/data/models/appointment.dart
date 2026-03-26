import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import 'model_parsers.dart';

class Appointment {
  const Appointment({
    this.id = '',
    required this.title,
    required this.startAt,
    this.eventDateTime,
    this.endAt,
    this.status = 'scheduled',
    this.hospitalName,
    this.doctorName,
    this.locationText,
    this.notes,
    this.remindersEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final Timestamp startAt;
  final Timestamp? eventDateTime;
  final Timestamp? endAt;
  final String status;
  final String? hospitalName;
  final String? doctorName;
  final String? locationText;
  final String? notes;
  final bool remindersEnabled;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  factory Appointment.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final parsedStartAt =
        asTimestamp(map[fields.scheduledAt] ?? map[fields.startAt]) ??
            Timestamp.now();
    final parsedLocation = map[fields.locationName] is String
        ? map[fields.locationName] as String
        : (map[fields.locationText] is String
            ? map[fields.locationText] as String
            : null);

    return Appointment(
      id: id,
      title: asString(map[fields.title]),
      startAt: parsedStartAt,
      eventDateTime: asTimestamp(map[fields.eventDateTime]) ??
          asTimestamp(map[fields.scheduledAt]) ??
          asTimestamp(map[fields.startAt]),
      endAt: asTimestamp(map[fields.endAt]),
      status: asString(map[fields.status], fallback: 'scheduled'),
      hospitalName: map[fields.hospitalName] is String
          ? map[fields.hospitalName] as String
          : null,
      doctorName: map[fields.doctorName] is String
          ? map[fields.doctorName] as String
          : null,
      locationText: parsedLocation,
      notes: map[fields.notes] is String ? map[fields.notes] as String : null,
      remindersEnabled: asBool(map[fields.remindersEnabled], fallback: true),
      createdAt: asTimestamp(map[fields.createdAt]),
      updatedAt: asTimestamp(map[fields.updatedAt]),
    );
  }

  Timestamp get scheduledAt => eventDateTime ?? startAt;
  String? get locationName => locationText;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      fields.title: title,
      fields.eventDateTime: scheduledAt,
      fields.scheduledAt: scheduledAt,
      fields.startAt: startAt,
      fields.endAt: endAt,
      fields.status: status,
      fields.hospitalName: hospitalName,
      fields.doctorName: doctorName,
      fields.locationName: locationName,
      fields.locationText: locationText,
      fields.notes: notes,
      fields.remindersEnabled: remindersEnabled,
    };
  }
}
