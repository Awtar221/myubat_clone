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

List<int> asIntList(dynamic value) {
  if (value is! List) {
    return const <int>[];
  }
  return value
      .map((item) {
        if (item is int) {
          return item;
        }
        if (item is num) {
          return item.toInt();
        }
        if (item is String) {
          return int.tryParse(item);
        }
        return null;
      })
      .whereType<int>()
      .toList(growable: false);
}

Map<String, dynamic>? asStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}
