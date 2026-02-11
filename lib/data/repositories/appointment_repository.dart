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
