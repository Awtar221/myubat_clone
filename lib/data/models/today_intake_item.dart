import 'package:cloud_firestore/cloud_firestore.dart';

class TodayIntakeItem {
  const TodayIntakeItem({
    required this.medicationId,
    required this.intakeId,
    required this.medicationName,
    required this.dosageText,
    required this.scheduledAt,
    required this.taken,
    this.instructions,
    this.takenAt,
  });

  final String medicationId;
  final String intakeId;
  final String medicationName;
  final String dosageText;
  final Timestamp scheduledAt;
  final bool taken;
  final String? instructions;
  final Timestamp? takenAt;
}
