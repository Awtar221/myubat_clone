import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import 'model_parsers.dart';

class ChatMessage {
  const ChatMessage({
    this.id = '',
    required this.role,
    required this.content,
    required this.createdAt,
    this.imageBase64,
  });

  final String id;
  final String role;
  final String content;
  final Timestamp createdAt;
  final String? imageBase64; // Storing base64 for local persistence/display

  factory ChatMessage.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return ChatMessage(
      id: id,
      role: asString(map[fields.role], fallback: 'user'),
      content: asString(map[fields.content]),
      createdAt: asTimestamp(map[fields.createdAt]) ?? Timestamp.now(),
      imageBase64: asString(map['imageBase64']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      fields.role: role,
      fields.content: content,
      fields.createdAt: createdAt,
      if (imageBase64 != null) 'imageBase64': imageBase64,
    };
  }
}
