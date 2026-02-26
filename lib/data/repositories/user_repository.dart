import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import '../../core/firestore/paths.dart';
import '../models/app_user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDocRef(String uid) {
    return _firestore.doc(userDoc(uid));
  }

  Future<void> createUserProfile(
    String uid,
    String email,
    String displayName,
  ) async {
    final payload = AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      profileCompleted: false,
      photoURL: null,
    ).toMapForCreate()
      ..addAll(<String, dynamic>{
        fields.createdAt: FieldValue.serverTimestamp(),
        fields.updatedAt: FieldValue.serverTimestamp(),
        fields.lastLoginAt: FieldValue.serverTimestamp(),
      });

    await _userDocRef(uid).set(payload, SetOptions(merge: true));
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final snapshot = await _userDocRef(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    final normalized = Map<String, dynamic>.from(data)
      ..putIfAbsent(fields.uid, () => uid);
    return AppUser.fromMap(normalized);
  }

  Future<void> updateProfile(AppUser user) async {
    final payload = user.toMapForUpdate()
      ..[fields.updatedAt] = FieldValue.serverTimestamp();
    
    await _userDocRef(user.uid).set(payload, SetOptions(merge: true));
  }

  Future<void> completeProfile(String uid, String displayName) async {
    await completeFullProfile(
      uid,
      fullName: displayName,
    );
  }

  Future<void> completeFullProfile(
    String uid, {
    required String fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? address,
    String? bloodType,
    int? heightCm,
    int? weightKg,
    String? allergies,
    String? medicalConditions,
    String? contactName,
    String? contactNumber,
  }) async {
    final normalizedFullName = fullName.trim();
    final personalMap = <String, dynamic>{
      fields.fullName: normalizedFullName,
      fields.dateOfBirth:
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
      fields.gender: _trimOrNull(gender),
      fields.phoneNumber: _trimOrNull(phoneNumber),
      fields.address: _trimOrNull(address),
    };

    final healthMap = <String, dynamic>{
      fields.bloodType: _trimOrNull(bloodType),
      fields.heightCm: heightCm,
      fields.weightKg: weightKg,
      fields.allergies: _trimOrNull(allergies),
      fields.medicalConditions: _trimOrNull(medicalConditions),
    };

    final emergencyMap = <String, dynamic>{
      fields.contactName: _trimOrNull(contactName),
      fields.contactNumber: _trimOrNull(contactNumber),
    };

    await _userDocRef(uid).set(<String, dynamic>{
      fields.displayName: normalizedFullName,
      fields.profileCompleted: true,
      fields.updatedAt: FieldValue.serverTimestamp(),
      fields.personal: personalMap,
      fields.health: healthMap,
      fields.emergency: emergencyMap,
    }, SetOptions(merge: true));
  }

  Future<void> updateDisplayName(String uid, String displayName) async {
    await _userDocRef(uid).update(<String, dynamic>{
      fields.displayName: displayName,
      fields.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  Stream<AppUser> userProfileStream(String uid) {
    return _userDocRef(uid).snapshots().map((snapshot) {
      final data =
          Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{});
      data.putIfAbsent(fields.uid, () => uid);
      return AppUser.fromMap(data);
    });
  }

  Future<void> touchLastLogin(String uid) async {
    final payload = <String, dynamic>{
      fields.lastLoginAt: FieldValue.serverTimestamp(),
      fields.updatedAt: FieldValue.serverTimestamp(),
    };

    try {
      await _userDocRef(uid).update(payload);
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') {
        rethrow;
      }
      await _userDocRef(uid).set(payload, SetOptions(merge: true));
    }
  }
}

String? _trimOrNull(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
