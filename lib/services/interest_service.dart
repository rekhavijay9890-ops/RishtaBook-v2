import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles the "interest" flow: one user sends interest to another,
/// the receiver accepts or rejects it, and an accept creates a
/// [MatchRecord] (see models/interest.dart) that both users can then
/// chat inside.
class InterestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _interests =>
      _db.collection('interests');

  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');

  /// Deterministic id so a match (and its chat thread) is always found
  /// under the same document regardless of who opens it first.
  static String matchIdFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  Future<bool> hasExistingInterest(String fromUid, String toUid) async {
    final forward = await _interests
        .where('fromUid', isEqualTo: fromUid)
        .where('toUid', isEqualTo: toUid)
        .limit(1)
        .get();
    if (forward.docs.isNotEmpty) return true;
    final backward = await _interests
        .where('fromUid', isEqualTo: toUid)
        .where('toUid', isEqualTo: fromUid)
        .limit(1)
        .get();
    return backward.docs.isNotEmpty;
  }

  Future<void> sendInterest({
    required String fromUid,
    required String fromName,
    required String toUid,
    required String toName,
  }) {
    return _interests.add({
      'fromUid': fromUid,
      'fromName': fromName,
      'toUid': toUid,
      'toName': toName,
      'status': 'pending',
      'createdAt': DateTime.now(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> receivedInterestsStream(String uid) {
    return _interests
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> sentInterestsStream(String uid) {
    return _interests.where('fromUid', isEqualTo: uid).snapshots();
  }

  Future<void> respondToInterest({
    required String interestId,
    required String fromUid,
    required String toUid,
    required bool accept,
  }) async {
    await _interests.doc(interestId).update({
      'status': accept ? 'accepted' : 'rejected',
    });

    if (accept) {
      final matchId = matchIdFor(fromUid, toUid);
      await _matches.doc(matchId).set({
        'participants': [fromUid, toUid],
        'createdAt': DateTime.now(),
        'lastMessage': '',
        'lastMessageAt': null,
      }, SetOptions(merge: true));
    }
  }

  /// All matches (mutual accepts) this user is part of, most recently
  /// active first - this is what the Chats tab lists.
  Stream<QuerySnapshot<Map<String, dynamic>>> matchesStream(String uid) {
    return _matches
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }
}
