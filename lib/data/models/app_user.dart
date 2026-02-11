import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import 'model_parsers.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? lastLoginAt;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final photoValue = map[fields.photoURL];

    return AppUser(
      uid: asString(map[fields.uid]),
      email: asString(map[fields.email]),
      displayName: asString(map[fields.displayName]),
      photoURL: photoValue is String ? photoValue : null,
      createdAt: asTimestamp(map[fields.createdAt]),
      updatedAt: asTimestamp(map[fields.updatedAt]),
      lastLoginAt: asTimestamp(map[fields.lastLoginAt]),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return <String, dynamic>{
      fields.uid: uid,
      fields.email: email,
      fields.displayName: displayName,
      fields.photoURL: photoURL,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return <String, dynamic>{
      fields.email: email,
      fields.displayName: displayName,
      fields.photoURL: photoURL,
    };
  }
}
