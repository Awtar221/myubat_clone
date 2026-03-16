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

  Future<void> ensureThread(
    String uid,
    String chatId, {
    String? title,
    String? model,
  }) async {
    await _chatThreadsCol(uid).doc(chatId).set(<String, dynamic>{
      fields.title: title,
      fields.model: model,
      fields.createdAt: FieldValue.serverTimestamp(),
      fields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    await ensureThread(uid, chatId);

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

  Stream<List<ChatMessage>> streamMessages({
    required String uid,
    required String threadId,
  }) {
    return chatMessagesStream(uid, threadId);
  }

  Future<void> updateMessageContent({
    required String uid,
    required String chatId,
    required String messageId,
    required String content,
  }) async {
    await _chatMessagesCol(uid, chatId).doc(messageId).set(<String, dynamic>{
      fields.content: content,
      fields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _chatThreadsCol(uid).doc(chatId).set(<String, dynamic>{
      fields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteMessagesByIds({
    required String uid,
    required String chatId,
    required Iterable<String> messageIds,
  }) async {
    final ids = messageIds.where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return;
    }

    for (var i = 0; i < ids.length; i += 400) {
      final batch = _firestore.batch();
      final chunk = ids.skip(i).take(400);
      for (final id in chunk) {
        batch.delete(_chatMessagesCol(uid, chatId).doc(id));
      }
      await batch.commit();
    }

    await _chatThreadsCol(uid).doc(chatId).set(<String, dynamic>{
      fields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearConversation({
    required String uid,
    required String chatId,
  }) async {
    while (true) {
      final snapshot = await _chatMessagesCol(uid, chatId).limit(400).get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < 400) {
        break;
      }
    }

    await _chatThreadsCol(uid).doc(chatId).set(<String, dynamic>{
      fields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> replaceMessageTail({
    required String uid,
    required String chatId,
    required String targetMessageId,
    required String updatedContent,
    required String assistantContent,
    Iterable<String> messageIdsToDelete = const <String>[],
  }) async {
    await ensureThread(uid, chatId);

    final batch = _firestore.batch();
    batch.set(
      _chatMessagesCol(uid, chatId).doc(targetMessageId),
      <String, dynamic>{
        fields.content: updatedContent,
        fields.updatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final idsToDelete = messageIdsToDelete
        .where((id) => id.trim().isNotEmpty && id != targetMessageId)
        .toSet();
    for (final messageId in idsToDelete) {
      batch.delete(_chatMessagesCol(uid, chatId).doc(messageId));
    }

    final assistantDoc = _chatMessagesCol(uid, chatId).doc();
    final assistantPayload = ChatMessage(
      role: 'assistant',
      content: assistantContent,
      createdAt: Timestamp.now(),
    ).toMap()
      ..[fields.createdAt] = FieldValue.serverTimestamp();
    batch.set(assistantDoc, assistantPayload);

    batch.set(
      _chatThreadsCol(uid).doc(chatId),
      <String, dynamic>{fields.updatedAt: FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
