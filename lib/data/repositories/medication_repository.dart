import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import '../../core/firestore/paths.dart';
import '../models/medication.dart';
import '../models/model_parsers.dart';
import '../models/today_intake_item.dart';

class MedicationRepository {
  MedicationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _medicationsCol(String uid) {
    return _firestore.collection(userMedicationsCol(uid));
  }

  CollectionReference<Map<String, dynamic>> _intakesCol(
    String uid,
    String medicationId,
  ) {
    return _firestore.collection(medicationIntakesCol(uid, medicationId));
  }

  Stream<List<Medication>> listMedicationsStream(String uid) {
    return _medicationsCol(uid)
        .orderBy(fields.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Medication.fromMap(doc.data(), id: doc.id))
          .toList(growable: false);
    });
  }

  Stream<List<Medication>> activeMedicationsStream(String uid) {
    return listMedicationsStream(uid).map((medications) {
      return medications
          .where((medication) => medication.isActive)
          .toList(growable: false);
    });
  }

  Future<void> ensureTodayIntakes(String uid, DateTime day) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final medications = await listMedicationsOnce(uid);

    for (final medication in medications) {
      if (!_isMedicationScheduledForDay(medication, dayStart, dayEnd)) {
        continue;
      }

      for (final scheduleTime in _effectiveScheduleTimes(medication)) {
        final parsed = _parseTime(scheduleTime);
        if (parsed == null) {
          continue;
        }

        final scheduledDateTime = DateTime(
          dayStart.year,
          dayStart.month,
          dayStart.day,
          parsed[0],
          parsed[1],
        );
        final intakeId = _intakeIdFor(scheduledDateTime);
        final intakeDocRef = _intakesCol(uid, medication.id).doc(intakeId);
        final intakeSnapshot = await intakeDocRef.get();
        if (intakeSnapshot.exists) {
          continue;
        }

        await intakeDocRef.set(<String, dynamic>{
          fields.scheduledAt: Timestamp.fromDate(scheduledDateTime),
          fields.taken: false,
          fields.takenAt: null,
          fields.createdAt: FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Stream<List<TodayIntakeItem>> todayIntakesStream(
    String uid,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    final normalizedDayStart = DateTime(
      dayStart.year,
      dayStart.month,
      dayStart.day,
    );
    final normalizedDayEnd = DateTime(dayEnd.year, dayEnd.month, dayEnd.day);
    final dayStartTs = Timestamp.fromDate(normalizedDayStart);
    final dayEndTs = Timestamp.fromDate(normalizedDayEnd);

    late final StreamController<List<TodayIntakeItem>> controller;
    StreamSubscription<List<Medication>>? medicationsSubscription;
    bool isEnsuringIntakes = false;
    final intakeSubscriptions =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final medicationsById = <String, Medication>{};
    final intakeDocsByMedicationId =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    void emit() {
      if (controller.isClosed) {
        return;
      }

      final items = <TodayIntakeItem>[];
      for (final medicationId in medicationsById.keys) {
        final medication = medicationsById[medicationId];
        if (medication == null) {
          continue;
        }
        final intakeDocs = intakeDocsByMedicationId[medicationId] ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        for (final doc in intakeDocs) {
          final data = doc.data();
          final scheduledAt = asTimestamp(data[fields.scheduledAt]) ??
              Timestamp.fromDate(normalizedDayStart);
          final dosageText = (medication.dosageText ?? '').trim();
          items.add(
            TodayIntakeItem(
              medicationId: medicationId,
              intakeId: doc.id,
              medicationName: medication.name,
              dosageText: dosageText.isEmpty ? '-' : dosageText,
              scheduledAt: scheduledAt,
              taken: data[fields.taken] is bool
                  ? data[fields.taken] as bool
                  : false,
              takenAt: asTimestamp(data[fields.takenAt]),
            ),
          );
        }
      }

      items.sort(
        (a, b) => a.scheduledAt.toDate().compareTo(b.scheduledAt.toDate()),
      );
      controller.add(items);
    }

    controller = StreamController<List<TodayIntakeItem>>(
      onListen: () {
        medicationsSubscription = activeMedicationsStream(uid).listen(
          (medications) {
            if (!isEnsuringIntakes) {
              isEnsuringIntakes = true;
              ensureTodayIntakes(uid, normalizedDayStart).whenComplete(() {
                isEnsuringIntakes = false;
              });
            }

            final todaysMeds = medications
                .where(
                  (medication) => _isMedicationScheduledForDay(
                    medication,
                    normalizedDayStart,
                    normalizedDayEnd,
                  ),
                )
                .where((medication) => medication.id.isNotEmpty)
                .toList(growable: false);

            final medicationIds =
                todaysMeds.map((medication) => medication.id).toSet();

            final removedMedicationIds = intakeSubscriptions.keys
                .where((id) => !medicationIds.contains(id))
                .toList(growable: false);
            for (final removedId in removedMedicationIds) {
              intakeSubscriptions.remove(removedId)?.cancel();
              medicationsById.remove(removedId);
              intakeDocsByMedicationId.remove(removedId);
            }

            for (final medication in todaysMeds) {
              medicationsById[medication.id] = medication;
              if (intakeSubscriptions.containsKey(medication.id)) {
                continue;
              }

              intakeSubscriptions[medication.id] = _intakesCol(
                uid,
                medication.id,
              )
                  .where(
                    fields.scheduledAt,
                    isGreaterThanOrEqualTo: dayStartTs,
                  )
                  .where(fields.scheduledAt, isLessThan: dayEndTs)
                  .orderBy(fields.scheduledAt)
                  .snapshots()
                  .listen(
                (snapshot) {
                  intakeDocsByMedicationId[medication.id] = snapshot.docs;
                  emit();
                },
                onError: controller.addError,
              );
            }

            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await medicationsSubscription?.cancel();
        for (final subscription in intakeSubscriptions.values) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }

  Future<void> toggleIntakeTaken(
    String uid,
    String medicationId,
    String intakeId,
    bool taken,
  ) async {
    await _intakesCol(uid, medicationId).doc(intakeId).set(<String, dynamic>{
      fields.taken: taken,
      fields.takenAt: taken ? FieldValue.serverTimestamp() : null,
      fields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Medication>> listMedicationsOnce(String uid) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _medicationsCol(uid)
          .orderBy(fields.createdAt, descending: true)
          .get();
    } catch (_) {
      snapshot = await _medicationsCol(uid).get();
    }

    return snapshot.docs
        .map((doc) => Medication.fromMap(doc.data(), id: doc.id))
        .toList(growable: false);
  }

  Future<String> upsertMedication(String uid, Medication medication) async {
    final colRef = _medicationsCol(uid);
    final docRef =
        medication.id.isEmpty ? colRef.doc() : colRef.doc(medication.id);

    final payload = medication.toMap()
      ..[fields.updatedAt] = FieldValue.serverTimestamp();

    if (medication.id.isEmpty) {
      payload[fields.createdAt] = FieldValue.serverTimestamp();
    }

    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  Future<void> deleteMedication(String uid, String medicationId) async {
    await _medicationsCol(uid).doc(medicationId).delete();
  }

  bool _isMedicationScheduledForDay(
    Medication medication,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    if (!medication.isActive || medication.id.isEmpty) {
      return false;
    }

    if (medication.daysOfWeek.isNotEmpty &&
        !medication.daysOfWeek.contains(dayStart.weekday)) {
      return false;
    }

    final medicationStart = medication.startDate?.toDate();
    if (medicationStart != null && !medicationStart.isBefore(dayEnd)) {
      return false;
    }

    final medicationEnd = medication.endDate?.toDate();
    if (medicationEnd != null && medicationEnd.isBefore(dayStart)) {
      return false;
    }

    return true;
  }

  List<String> _effectiveScheduleTimes(Medication medication) {
    final normalizedTimes = <String>[];
    for (final scheduleTime in medication.scheduleTimes) {
      final parsed = _parseTime(scheduleTime);
      if (parsed == null) {
        continue;
      }
      final hour = parsed[0].toString().padLeft(2, '0');
      final minute = parsed[1].toString().padLeft(2, '0');
      normalizedTimes.add('$hour:$minute');
    }

    if (normalizedTimes.isEmpty) {
      return const <String>['09:00'];
    }
    return normalizedTimes.toSet().toList(growable: false);
  }

  List<int>? _parseTime(String rawTime) {
    final text = rawTime.trim();
    if (text.isEmpty) {
      return null;
    }

    final hhmm = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(text);
    if (hhmm != null) {
      final hour = int.parse(hhmm.group(1)!);
      final minute = int.parse(hhmm.group(2)!);
      return <int>[hour, minute];
    }

    final amPm = RegExp(
      r'^([1-9]|1[0-2]):([0-5]\d)\s*([AaPp][Mm])$',
    ).firstMatch(text);
    if (amPm != null) {
      final hour12 = int.parse(amPm.group(1)!);
      final minute = int.parse(amPm.group(2)!);
      final suffix = amPm.group(3)!.toLowerCase();
      final isPm = suffix == 'pm';
      final hour24 = (hour12 % 12) + (isPm ? 12 : 0);
      return <int>[hour24, minute];
    }

    return null;
  }

  String _intakeIdFor(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year$month${day}_$hour$minute';
  }
}
