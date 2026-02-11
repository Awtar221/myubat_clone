import 'package:cloud_firestore/cloud_firestore.dart';

String asString(dynamic value, {String fallback = ''}) {
  if (value is String) {
    return value;
  }
  return fallback;
}

Timestamp? asTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value;
  }
  if (value is DateTime) {
    return Timestamp.fromDate(value);
  }
  return null;
}

bool asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  return fallback;
}

List<String> asStringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}
