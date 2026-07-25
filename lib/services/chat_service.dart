import 'package:cloud_firestore/cloud_firestore.dart';

/// Messages inside a single match's chat thread:
/// `matches/{matchId}/messages/{messageId}`.
class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(String matchId) =>
      _db.collection('matches').doc(matchId).collection('messages');

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String matchId) {
    return _messages(matchId).orderBy('sentAt', descending: false).snapshots();
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final now = DateTime.now();
    await _messages(matchId).add({
      'senderId': senderId,
      'text': text,
      'sentAt': now,
    });
    await _db.collection('matches').doc(matchId).update({
      'lastMessage': text,
      'lastMessageAt': now,
    });
  }
}
