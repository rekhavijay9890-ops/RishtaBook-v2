import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/app_config.dart';
import 'notification_service.dart';

/// Messages inside a single match's chat thread:
/// `matches/{matchId}/messages/{messageId}`.
class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> _messages(String matchId) =>
      _db.collection('matches').doc(matchId).collection('messages');

  /// Uploads a chat photo to Supabase Storage (same bucket + `{uid}/...`
  /// path convention as ProfileService.uploadProfilePhoto - this app never
  /// enabled Firebase Storage, see AppConfig's doc). Uploading under the
  /// SENDER's own uid folder (not e.g. a matchId-keyed path) matters here:
  /// whatever bucket policy already allows profile-photo uploads is almost
  /// certainly scoped to "my own uid folder", so reusing that exact shape
  /// avoids needing a second, separate Storage policy just for chat images.
  Future<String> uploadChatImage(String senderUid, File file) async {
    final path = '$senderUid/chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storage = Supabase.instance.client.storage.from(AppConfig.supabasePhotosBucket);
    await storage.upload(path, file);
    return storage.getPublicUrl(path);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String matchId) {
    return _messages(matchId).orderBy('sentAt', descending: false).snapshots();
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    await _messages(matchId).add({
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'sentAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('matches').doc(matchId).update({
      'lastMessage': imageUrl != null ? '📷 Photo' : text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await _notifyRecipient(matchId: matchId, senderId: senderId, preview: imageUrl != null ? '📷 Photo' : text);
  }

  /// Best-effort: looks up the other participant + the sender's own name to
  /// leave them a notification. Never blocks/fails the send itself - a
  /// notification hiccup shouldn't stop a message from going through.
  Future<void> _notifyRecipient({required String matchId, required String senderId, required String preview}) async {
    try {
      final matchDoc = await _db.collection('matches').doc(matchId).get();
      final participants = List<String>.from(matchDoc.data()?['participants'] ?? const []);
      final recipientUid = participants.firstWhere((p) => p != senderId, orElse: () => '');
      if (recipientUid.isEmpty) return;
      final senderDoc = await _db.collection('users').doc(senderId).get();
      final senderName = (senderDoc.data()?['fullName'] as String?)?.trim();
      await _notificationService.notifyNewMessage(
        recipientUid,
        senderName: (senderName?.isNotEmpty ?? false) ? senderName! : 'New message',
        preview: preview,
        matchId: matchId,
      );
    } catch (_) {}
  }

  /// Mark this user as having seen all messages in this match up to now.
  Future<void> markSeen(String matchId, String uid) {
    return _db.collection('matches').doc(matchId).update({
      'lastSeen_$uid': FieldValue.serverTimestamp(),
    });
  }

  /// Count of messages in this match sent AFTER this user's lastSeen timestamp.
  Stream<int> unreadCountStream(String matchId, String uid) {
    return _db.collection('matches').doc(matchId).snapshots().asyncMap((snap) async {
      final data = snap.data();
      if (data == null) return 0;
      final lastSeen = (data['lastSeen_$uid'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final qs = await _messages(matchId)
          .where('sentAt', isGreaterThan: Timestamp.fromDate(lastSeen))
          .where('senderId', isNotEqualTo: uid)
          .get();
      return qs.docs.length;
    });
  }

  /// Total unread messages across ALL matches for this user. Runs the
  /// per-match subqueries in parallel (Future.wait) rather than one at a
  /// time - this badge recomputes on every match-list change, and a
  /// sequential loop meant N round trips back-to-back for N matches,
  /// adding directly to how long the app feels slow to settle right after
  /// sign-in.
  Stream<int> totalUnreadStream(String uid) {
    return _db
        .collection('matches')
        .where('participants', arrayContains: uid)
        .snapshots()
        .asyncMap((qs) async {
      final counts = await Future.wait<int>(qs.docs.map((doc) async {
        final data = doc.data();
        final lastSeen = (data['lastSeen_$uid'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final msgs = await _messages(doc.id)
            .where('sentAt', isGreaterThan: Timestamp.fromDate(lastSeen))
            .where('senderId', isNotEqualTo: uid)
            .get();
        return msgs.docs.length;
      }));
      return counts.fold<int>(0, (a, b) => a + b);
    });
  }
}
