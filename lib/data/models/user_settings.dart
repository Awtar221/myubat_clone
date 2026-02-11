import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import 'model_parsers.dart';

class UserSettings {
  const UserSettings({
    this.notificationsEnabled = true,
    this.language = 'en',
    this.theme = 'system',
    this.updatedAt,
  });

  final bool notificationsEnabled;
  final String language;
  final String theme;
  final Timestamp? updatedAt;

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationsEnabled:
          asBool(map[fields.notificationsEnabled], fallback: true),
      language: asString(map[fields.language], fallback: 'en'),
      theme: asString(map[fields.theme], fallback: 'system'),
      updatedAt: asTimestamp(map[fields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      fields.notificationsEnabled: notificationsEnabled,
      fields.language: language,
      fields.theme: theme,
    };
  }
}
