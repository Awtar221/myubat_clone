import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import '../../core/firestore/paths.dart';
import '../models/user_settings.dart';

class SettingsRepository {
  SettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) {
    return _firestore.doc(userSettingsDoc(uid));
  }

  Stream<UserSettings> getSettingsStream(String uid) {
    return _settingsDoc(uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      return UserSettings.fromMap(data);
    });
  }

  Future<UserSettings?> getSettingsOnce(String uid) async {
    final snapshot = await _settingsDoc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return UserSettings.fromMap(data);
  }

  Future<void> updateSettings(String uid, Map<String, dynamic> partial) async {
    final payload = Map<String, dynamic>.from(partial)
      ..[fields.updatedAt] = FieldValue.serverTimestamp();

    await _settingsDoc(uid).set(payload, SetOptions(merge: true));
  }
}
