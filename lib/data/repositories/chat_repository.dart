import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_fields.dart' as fields;
import '../../core/firestore/paths.dart';
import '../models/chat_message.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _chatThreadsCol(String uid) {
    return _firestore.collection(userChatsCol(uid));
  }

  CollectionReference<Map<String, dynamic>> _chatMessagesCol(
    String uid,
    String chatId,
  ) {
    return _firestore.collection(chatMessagesCol(uid, chatId));
  }

  Future<String> createChatThread(
    String uid, {
    String? title,
    String? model,
  }) async {
    final docRef = await _chatThreadsCol(uid).add(<String, dynamic>{
      fields.title: title,
      fields.model: model,
      fields.createdAt: FieldValue.serverTimestamp(),
      fields.updatedAt: FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<String> addMessage(
    String uid,
    String chatId,
    ChatMessage message,
  ) async {
    final payload = message.toMap()
      ..[fields.createdAt] = FieldValue.serverTimestamp();

    final docRef = await _chatMessagesCol(uid, chatId).add(payload);

    await _chatThreadsCol(uid).doc(chatId).set(<String, dynamic>{
      fields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return docRef.id;
  }

  Stream<List<ChatMessage>> chatMessagesStream(String uid, String chatId) {
    return _chatMessagesCol(uid, chatId)
        .orderBy(fields.createdAt)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), id: doc.id))
          .toList(growable: false);
    });
  }
}
