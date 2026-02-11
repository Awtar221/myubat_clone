import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import '../../core/firestore/paths.dart';
import '../models/medication.dart';

class MedicationRepository {
  MedicationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _medicationsCol(String uid) {
    return _firestore.collection(userMedicationsCol(uid));
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
}
