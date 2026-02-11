import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import 'model_parsers.dart';

class ChatThread {
  const ChatThread({
    this.id = '',
    this.title,
    this.model,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? title;
  final String? model;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  factory ChatThread.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return ChatThread(
      id: id,
      title: map[fields.title] is String ? map[fields.title] as String : null,
      model: map[fields.model] is String ? map[fields.model] as String : null,
      createdAt: asTimestamp(map[fields.createdAt]),
      updatedAt: asTimestamp(map[fields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      fields.title: title,
      fields.model: model,
    };
  }
}
