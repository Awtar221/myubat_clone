import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/firestore/paths.dart';
import '../notification/notification_service.dart';

class AccountService {
  AccountService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService =
            notificationService ?? NotificationService.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  Future<void> signOut() async {
    await _notificationService.cancelAllNotifications();
    await _auth.signOut();
  }

  Future<void> deleteCurrentAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user found.');
    }

    final email = (user.email ?? '').trim();
    if (email.isEmpty) {
      throw StateError(
        'This account cannot be deleted with password confirmation.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
    await _deleteUserData(user.uid);
    await _notificationService.cancelAllNotifications();
    await user.delete();
    await _auth.signOut();
  }

  Future<void> _deleteUserData(String uid) async {
    await _deleteChats(uid);
    await _deleteMedications(uid);
    await _deleteAppointments(uid);
    await _deleteDocumentIfExists(_firestore.doc(userSettingsDoc(uid)));
    await _deleteDocumentIfExists(_firestore.doc(userDoc(uid)));
  }

  Future<void> _deleteChats(String uid) async {
    final chats = await _firestore.collection(userChatsCol(uid)).get();
    for (final chat in chats.docs) {
      await _deleteCollection(
          _firestore.collection(chatMessagesCol(uid, chat.id)));
      await chat.reference.delete();
    }
  }

  Future<void> _deleteMedications(String uid) async {
    final medications =
        await _firestore.collection(userMedicationsCol(uid)).get();
    for (final medication in medications.docs) {
      await _deleteCollection(
        _firestore.collection(medicationIntakesCol(uid, medication.id)),
      );
      await medication.reference.delete();
    }
  }

  Future<void> _deleteAppointments(String uid) async {
    await _deleteCollection(_firestore.collection(userAppointmentsCol(uid)));
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(400).get();
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
  }

  Future<void> _deleteDocumentIfExists(
    DocumentReference<Map<String, dynamic>> document,
  ) async {
    final snapshot = await document.get();
    if (snapshot.exists) {
      await document.delete();
    }
  }
}
