import 'package:cloud_firestore/cloud_firestore.dart';

/// Credits: the app's pay-to-contact currency. One field on the user doc
/// (`credits`, an int) plus an append-only `users/{uid}/transactions`
/// ledger so the balance is always reconstructable and auditable.
///
/// SECURITY NOTE: every credit/debit here is a plain client-side Firestore
/// write, matching the rest of this app's 100%-client-driven architecture.
/// For a production launch, purchase grants (see [completePurchase]) must
/// move behind a Cloud Function that verifies the Razorpay payment
/// signature server-side before crediting — a client can otherwise call
/// this method directly without ever paying. Spend paths (chat/profile
/// unlock) are reasonably safe since they only ever decrement.
class CreditService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int signupBonus = 100;
  static const int chatUnlockCost = 30;
  static const int profileUnlockCost = 20;
  static const int referralBonus = 50;
  static const int freeSearchPreviewCount = 3;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _txns(String uid) => _userDoc(uid).collection('transactions');

  Stream<int> creditsStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      final v = doc.data()?['credits'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> transactionsStream(String uid, {int limit = 30}) {
    return _txns(uid).orderBy('createdAt', descending: true).limit(limit).snapshots();
  }

  Future<void> _logTxn(String uid, {required String type, required int delta, required String label}) {
    return _txns(uid).add({
      'type': type,
      'delta': delta,
      'label': label,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deduct [amount] credits if the balance allows it. Returns false
  /// (no-op) if the balance is insufficient.
  Future<bool> spend(String uid, {required int amount, required String type, required String label}) async {
    final ok = await _db.runTransaction<bool>((txn) async {
      final snap = await txn.get(_userDoc(uid));
      final current = (snap.data()?['credits'] as num?)?.toInt() ?? 0;
      if (current < amount) return false;
      txn.update(_userDoc(uid), {'credits': current - amount});
      return true;
    });
    if (ok) await _logTxn(uid, type: type, delta: -amount, label: label);
    return ok;
  }

  Future<void> grant(String uid, {required int amount, required String type, required String label}) async {
    await _userDoc(uid).set({'credits': FieldValue.increment(amount)}, SetOptions(merge: true));
    await _logTxn(uid, type: type, delta: amount, label: label);
  }

  /// Charges [chatUnlockCost] the first time a user opens a given match's
  /// chat thread; free on every subsequent open. Returns true if the chat
  /// is (now, or already was) unlocked, false if the balance was too low.
  Future<bool> unlockChatIfNeeded(String matchId, String uid, {required String otherName}) async {
    final matchDoc = _db.collection('matches').doc(matchId);
    final unlockedField = 'unlockedBy_$uid';

    final result = await _db.runTransaction<bool>((txn) async {
      final matchSnap = await txn.get(matchDoc);
      if (matchSnap.data()?[unlockedField] == true) return true;

      final userSnap = await txn.get(_userDoc(uid));
      final current = (userSnap.data()?['credits'] as num?)?.toInt() ?? 0;
      if (current < chatUnlockCost) return false;

      txn.update(_userDoc(uid), {'credits': current - chatUnlockCost});
      txn.set(matchDoc, {unlockedField: true}, SetOptions(merge: true));
      return true;
    });

    if (result) {
      final matchSnap = await matchDoc.get();
      final alreadyLogged = matchSnap.data()?['${unlockedField}_logged'] == true;
      if (!alreadyLogged) {
        await _logTxn(uid, type: 'chat_opened', delta: -chatUnlockCost, label: otherName);
        await matchDoc.set({'${unlockedField}_logged': true}, SetOptions(merge: true));
      }
    }
    return result;
  }

  Future<bool> isChatUnlocked(String matchId, String uid) async {
    final doc = await _db.collection('matches').doc(matchId).get();
    return doc.data()?['unlockedBy_$uid'] == true;
  }

  /// Unlocks a locked search result (full profile view) for [profileUnlockCost]
  /// credits, remembered on the viewer's own doc so it's never charged twice.
  Future<bool> unlockProfile(String uid, {required String targetUid, required String targetName}) async {
    final already = await isProfileUnlocked(uid, targetUid);
    if (already) return true;

    final ok = await _db.runTransaction<bool>((txn) async {
      final snap = await txn.get(_userDoc(uid));
      final current = (snap.data()?['credits'] as num?)?.toInt() ?? 0;
      if (current < profileUnlockCost) return false;
      txn.update(_userDoc(uid), {
        'credits': current - profileUnlockCost,
        'unlockedProfileUids': FieldValue.arrayUnion([targetUid]),
      });
      return true;
    });
    if (ok) await _logTxn(uid, type: 'profile_unlocked', delta: -profileUnlockCost, label: targetName);
    return ok;
  }

  Future<bool> isProfileUnlocked(String uid, String targetUid) async {
    final doc = await _userDoc(uid).get();
    final list = List<String>.from(doc.data()?['unlockedProfileUids'] ?? []);
    return list.contains(targetUid);
  }

  Future<void> grantSignupBonus(String uid) => grant(uid, amount: signupBonus, type: 'signup_bonus', label: 'Welcome bonus');

  Future<void> grantReferralBonus(String uid, {required String friendName}) =>
      grant(uid, amount: referralBonus, type: 'referral', label: friendName);

  /// Called after the Razorpay checkout success callback. See the class-level
  /// SECURITY NOTE — this trusts the client, which is fine for development
  /// but must be replaced by a verified server-side grant before launch.
  Future<void> completePurchase(String uid, {required int credits, required String label}) =>
      grant(uid, amount: credits, type: 'purchase', label: label);
}
