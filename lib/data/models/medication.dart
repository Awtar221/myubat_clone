import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import 'model_parsers.dart';

class Medication {
  const Medication({
    this.id = '',
    required this.name,
    this.dosage,
    this.instructions,
    this.times = const <String>[],
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? dosage;
  final String? instructions;
  final List<String> times;
  final Timestamp? startDate;
  final Timestamp? endDate;
  final bool isActive;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  factory Medication.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return Medication(
      id: id,
      name: asString(map[fields.name]),
      dosage:
          map[fields.dosage] is String ? map[fields.dosage] as String : null,
      instructions: map[fields.instructions] is String
          ? map[fields.instructions] as String
          : null,
      times: asStringList(map[fields.times]),
      startDate: asTimestamp(map[fields.startDate]),
      endDate: asTimestamp(map[fields.endDate]),
      isActive: asBool(map[fields.isActive], fallback: true),
      createdAt: asTimestamp(map[fields.createdAt]),
      updatedAt: asTimestamp(map[fields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      fields.name: name,
      fields.dosage: dosage,
      fields.instructions: instructions,
      fields.times: times,
      fields.startDate: startDate,
      fields.endDate: endDate,
      fields.isActive: isActive,
    };
  }
}
