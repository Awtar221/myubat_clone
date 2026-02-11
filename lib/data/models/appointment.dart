import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import 'model_parsers.dart';

class Appointment {
  const Appointment({
    this.id = '',
    required this.title,
    required this.startAt,
    this.endAt,
    this.status = 'scheduled',
    this.hospitalName,
    this.doctorName,
    this.locationText,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final Timestamp startAt;
  final Timestamp? endAt;
  final String status;
  final String? hospitalName;
  final String? doctorName;
  final String? locationText;
  final String? notes;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  factory Appointment.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return Appointment(
      id: id,
      title: asString(map[fields.title]),
      startAt: asTimestamp(map[fields.startAt]) ?? Timestamp.now(),
      endAt: asTimestamp(map[fields.endAt]),
      status: asString(map[fields.status], fallback: 'scheduled'),
      hospitalName: map[fields.hospitalName] is String
          ? map[fields.hospitalName] as String
          : null,
      doctorName: map[fields.doctorName] is String
          ? map[fields.doctorName] as String
          : null,
      locationText: map[fields.locationText] is String
          ? map[fields.locationText] as String
          : null,
      notes: map[fields.notes] is String ? map[fields.notes] as String : null,
      createdAt: asTimestamp(map[fields.createdAt]),
      updatedAt: asTimestamp(map[fields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      fields.title: title,
      fields.startAt: startAt,
      fields.endAt: endAt,
      fields.status: status,
      fields.hospitalName: hospitalName,
      fields.doctorName: doctorName,
      fields.locationText: locationText,
      fields.notes: notes,
    };
  }
}
