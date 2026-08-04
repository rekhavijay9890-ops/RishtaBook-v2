import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notifications: `users/{uid}/notifications/{id}`. Client-driven
/// like the rest of this app - whichever screen/service triggers an event
/// (a message send, a profile view, a credit grant, an interest accept)
/// writes directly into the OTHER user's subcollection. See firestore.rules
/// for why that cross-user create is allowed while read/update/delete stay
/// owner-only.
class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifs(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Future<void> _create(
    String uid, {
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> meta = const {},
  }) {
    return _notifs(uid).add({
      'type': type,
      'title': title,
      'body': body,
      'meta': meta,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> notifyCreditAdded(String uid, {required int amount, required String label}) {
    return _create(
      uid,
      type: 'credit',
      title: 'क्रेडिट मिला / Credits added',
      body: '+$amount credits · $label',
      meta: {'amount': amount, 'label': label},
    );
  }

  Future<void> notifyProfileViewed(String uid, {required String viewerName}) {
    return _create(
      uid,
      type: 'profile_view',
      title: 'प्रोफ़ाइल देखी गई / Profile viewed',
      body: '$viewerName ने आपकी प्रोफ़ाइल देखी / $viewerName viewed your profile',
      meta: {'viewerName': viewerName},
    );
  }

  Future<void> notifyNewMessage(String uid, {required String senderName, required String preview, required String matchId}) {
    return _create(
      uid,
      type: 'message',
      title: senderName,
      body: preview,
      meta: {'matchId': matchId, 'senderName': senderName},
    );
  }

  Future<void> notifyInterestReceived(String uid, {required String fromName}) {
    return _create(
      uid,
      type: 'interest_received',
      title: 'नई रुचि / New interest',
      body: '$fromName ने आपमें रुचि दिखाई / $fromName sent you interest',
      meta: {'fromName': fromName},
    );
  }

  Future<void> notifyInterestAccepted(String uid, {required String byName}) {
    return _create(
      uid,
      type: 'interest_accepted',
      title: 'रुचि स्वीकार हुई / Interest accepted',
      body: '$byName ने आपकी रुचि स्वीकार की / $byName accepted your interest',
      meta: {'byName': byName},
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> notificationsStream(String uid, {int limit = 50}) {
    return _notifs(uid).orderBy('createdAt', descending: true).limit(limit).snapshots();
  }

  Stream<int> unreadCountStream(String uid) {
    return _notifs(uid).where('read', isEqualTo: false).snapshots().map((s) => s.docs.length);
  }

  Future<void> markRead(String uid, String notificationId) {
    return _notifs(uid).doc(notificationId).update({'read': true});
  }

  Future<void> markAllRead(String uid) async {
    final unread = await _notifs(uid).where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
