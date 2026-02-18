import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import 'model_parsers.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.profileCompleted = false,
    this.personal,
    this.health,
    this.emergency,
    this.photoURL,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final bool profileCompleted;
  final Map<String, dynamic>? personal;
  final Map<String, dynamic>? health;
  final Map<String, dynamic>? emergency;
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
      profileCompleted: asBool(map[fields.profileCompleted], fallback: false),
      personal: asStringDynamicMap(map[fields.personal]),
      health: asStringDynamicMap(map[fields.health]),
      emergency: asStringDynamicMap(map[fields.emergency]),
      photoURL: photoValue is String ? photoValue : null,
      createdAt: asTimestamp(map[fields.createdAt]),
      updatedAt: asTimestamp(map[fields.updatedAt]),
      lastLoginAt: asTimestamp(map[fields.lastLoginAt]),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    final map = <String, dynamic>{
      fields.uid: uid,
      fields.email: email,
      fields.displayName: displayName,
      fields.profileCompleted: profileCompleted,
      fields.photoURL: photoURL,
    };

    if (personal != null) {
      map[fields.personal] = personal;
    }
    if (health != null) {
      map[fields.health] = health;
    }
    if (emergency != null) {
      map[fields.emergency] = emergency;
    }
    return map;
  }

  Map<String, dynamic> toMapForUpdate() {
    final map = <String, dynamic>{
      fields.email: email,
      fields.displayName: displayName,
      fields.profileCompleted: profileCompleted,
      fields.photoURL: photoURL,
    };

    if (personal != null) {
      map[fields.personal] = personal;
    }
    if (health != null) {
      map[fields.health] = health;
    }
    if (emergency != null) {
      map[fields.emergency] = emergency;
    }
    return map;
  }
}
