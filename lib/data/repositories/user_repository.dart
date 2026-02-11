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
      photoURL: null,
    ).toMapForCreate()
      ..addAll(<String, dynamic>{
        fields.createdAt: FieldValue.serverTimestamp(),
        fields.updatedAt: FieldValue.serverTimestamp(),
        fields.lastLoginAt: FieldValue.serverTimestamp(),
      });

    await _userDocRef(uid).set(payload, SetOptions(merge: true));
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
