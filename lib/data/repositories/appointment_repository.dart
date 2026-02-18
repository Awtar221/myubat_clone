import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import '../../core/firestore/paths.dart';
import '../models/appointment.dart';

class AppointmentRepository {
  AppointmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _appointmentsCol(String uid) {
    return _firestore.collection(userAppointmentsCol(uid));
  }

  Stream<List<Appointment>> listAppointmentsStream(String uid) {
    return _appointmentsCol(uid)
        .orderBy(fields.startAt, descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appointment.fromMap(doc.data(), id: doc.id))
          .toList(growable: false);
    });
  }

  Stream<Appointment?> nextUpcomingAppointmentStream(String uid) {
    return listAppointmentsStream(uid).map((appointments) {
      final now = DateTime.now();

      Appointment? nextAppointment;
      for (final appointment in appointments) {
        final status = appointment.status.toLowerCase();
        if (status == 'completed' || status == 'cancelled') {
          continue;
        }

        final scheduledTime = appointment.scheduledAt.toDate();
        if (!scheduledTime.isAfter(now)) {
          continue;
        }

        if (nextAppointment == null ||
            scheduledTime.isBefore(nextAppointment.scheduledAt.toDate())) {
          nextAppointment = appointment;
        }
      }

      return nextAppointment;
    });
  }

  Future<List<Appointment>> listAppointmentsOnce(String uid) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _appointmentsCol(uid)
          .orderBy(fields.startAt, descending: false)
          .get();
    } catch (_) {
      snapshot = await _appointmentsCol(uid).get();
    }

    return snapshot.docs
        .map((doc) => Appointment.fromMap(doc.data(), id: doc.id))
        .toList(growable: false);
  }

  Future<String> upsertAppointment(String uid, Appointment appointment) async {
    final colRef = _appointmentsCol(uid);
    final docRef =
        appointment.id.isEmpty ? colRef.doc() : colRef.doc(appointment.id);

    final payload = appointment.toMap()
      ..[fields.updatedAt] = FieldValue.serverTimestamp();

    if (appointment.id.isEmpty) {
      payload[fields.createdAt] = FieldValue.serverTimestamp();
    }

    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  Future<void> deleteAppointment(String uid, String appointmentId) async {
    await _appointmentsCol(uid).doc(appointmentId).delete();
  }
}
