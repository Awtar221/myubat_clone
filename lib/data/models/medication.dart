import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import 'model_parsers.dart';

class Medication {
  Medication({
    this.id = '',
    required this.name,
    String? dosageText,
    String? dosage,
    this.instructions,
    List<String> scheduleTimes = const <String>[],
    List<String>? times,
    this.startDate,
    this.endDate,
    this.daysOfWeek = const <int>[],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  })  : dosageText = dosageText ?? dosage,
        scheduleTimes = scheduleTimes.isNotEmpty
            ? scheduleTimes
            : (times ?? const <String>[]);

  final String id;
  final String name;
  final String? dosageText;
  final String? instructions;
  final List<String> scheduleTimes;
  final Timestamp? startDate;
  final Timestamp? endDate;
  final List<int> daysOfWeek;
  final bool isActive;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  String? get dosage => dosageText;
  List<String> get times => scheduleTimes;

  factory Medication.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final parsedDosageText = asString(
      map[fields.dosageText] ?? map[fields.dosage],
      fallback: '',
    ).trim();
    final parsedScheduleTimes = asStringList(
      map[fields.scheduleTimes] ?? map[fields.times],
    );
    return Medication(
      id: id,
      name: asString(map[fields.name]),
      dosageText: parsedDosageText.isEmpty ? null : parsedDosageText,
      instructions: map[fields.instructions] is String
          ? map[fields.instructions] as String
          : null,
      scheduleTimes: parsedScheduleTimes,
      startDate: asTimestamp(map[fields.startDate]),
      endDate: asTimestamp(map[fields.endDate]),
      daysOfWeek: asIntList(map[fields.daysOfWeek]),
      isActive: asBool(map[fields.isActive], fallback: true),
      createdAt: asTimestamp(map[fields.createdAt]),
      updatedAt: asTimestamp(map[fields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      fields.name: name,
      fields.dosageText: dosageText,
      fields.dosage: dosageText,
      fields.instructions: instructions,
      fields.scheduleTimes: scheduleTimes,
      fields.times: scheduleTimes,
      fields.daysOfWeek: daysOfWeek,
      fields.startDate: startDate,
      fields.endDate: endDate,
      fields.isActive: isActive,
    };
  }
}
