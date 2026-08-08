import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

/// Credits: the app's pay-to-contact currency. One field on the user doc
/// (`credits`, an int) plus an append-only `users/{uid}/transactions`
/// ledger so the balance is always reconstructable and auditable.
///
/// SECURITY NOTE: every credit/debit here is a plain client-side Firestore
/// write, matching the rest of this app's 100%-client-driven architecture -
/// EXCEPT purchases, which is exactly the one path real money changes hands
/// on. That grant now happens server-side only, in
/// supabase/functions/razorpay-webhook, triggered by Razorpay's own
/// `payment.captured` webhook (signature-verified) rather than trusted from
/// the client - see that function's doc comment for the full flow. Spend
/// paths (chat/profile unlock) stay client-side since they only ever
/// decrement, so there's nothing to gain by tampering with them.
class CreditService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int signupBonus = 100;
  static const int chatUnlockCost = 30;
  static const int profileUnlockCost = 20;
  static const int referralBonus = 50;
  static const int freeSearchPreviewCount = 3;
  static const int adRewardAmount = 10;
  static const int maxAdRewardsPerDay = 5;
  static const int boostCost = 50;
  static const Duration boostDuration = Duration(hours: 24);

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _txns(String uid) => _userDoc(uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> _invites(String uid) => _userDoc(uid).collection('referralInvites');

  /// Referral bonus is admin-configurable at runtime via the `config/app`
  /// Firestore doc (see Admin screen), not just a compile-time constant.
  /// Falls back to [referralBonus] if that doc/field doesn't exist yet.
  /// firestore.rules reads the SAME doc when validating a referral credit
  /// write, so client and rule always agree on the current amount.
  Future<int> getReferralBonusAmount() async {
    final doc = await _db.collection('config').doc('app').get();
    final v = doc.data()?['referralBonus'];
    if (v is num) return v.toInt();
    return referralBonus;
  }

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

  /// Uses `.update()`, not `.set(merge:true)`, deliberately: it must fail
  /// (and be caught by the caller) rather than silently create a phantom
  /// profile doc when [uid] doesn't already exist - the referral path
  /// calls this with a user-typed uid that may be invalid or fake.
  Future<void> grant(String uid, {required int amount, required String type, required String label}) async {
    await _userDoc(uid).update({'credits': FieldValue.increment(amount)});
    await _logTxn(uid, type: type, delta: amount, label: label);
    await NotificationService().notifyCreditAdded(uid, amount: amount, label: label);
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

  Future<void> grantReferralBonus(String uid, {required String friendName}) async {
    final amount = await getReferralBonusAmount();
    await grant(uid, amount: amount, type: 'referral', label: friendName);
  }

  static String normalizePhone(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

  /// Short, human-typeable referral code (e.g. "RB4X9K2P") generated once
  /// at signup and stored on the user doc — much friendlier to read aloud
  /// or type than the raw Firebase Auth uid it used to be.
  static const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I
  static String generateReferralCode() {
    final rnd = Random.secure();
    final code = List.generate(6, (_) => _codeChars[rnd.nextInt(_codeChars.length)]).join();
    return 'RB$code';
  }

  /// Records that [uid] intends to invite [phone] — shown in their "Your
  /// invites" list as pending. Does NOT send anything itself; the caller
  /// (ReferralScreen) opens the device's native SMS composer separately,
  /// since there's no SMS gateway/backend in this app to send on their
  /// behalf.
  Future<void> logManualInvite(String uid, String phone) {
    return _invites(uid).add({
      'phone': normalizePhone(phone),
      'status': 'invited',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> manualInvitesStream(String uid) {
    return _invites(uid).orderBy('createdAt', descending: true).snapshots();
  }

  /// Called right after a new signup redeems a referral code: if the
  /// referrer had logged a manual invite for this new user's phone number,
  /// mark it completed so it stops showing as pending. Best-effort - if
  /// the referrer shared a link/code instead of using "add by mobile", or
  /// the phone numbers don't match, this just finds nothing and no-ops;
  /// the referral bonus itself (already granted separately) still stands.
  Future<void> tryCompleteManualInvite(String referrerUid, {required String phone}) async {
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) return;
    final matches = await _invites(referrerUid)
        .where('phone', isEqualTo: normalized)
        .where('status', isEqualTo: 'invited')
        .limit(1)
        .get();
    if (matches.docs.isEmpty) return;
    await matches.docs.first.reference.update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }


  String _todayKey() {
    final n = DateTime.now().toUtc();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  int _adRewardsUsedToday(Map<String, dynamic>? data) {
    if (data == null) return 0;
    if (data['adRewardsDate'] != _todayKey()) return 0;
    return (data['adRewardsCountToday'] as num?)?.toInt() ?? 0;
  }

  /// How many rewarded ads this user can still watch today (resets at UTC
  /// midnight). Check this before showing the "Watch ad" button as enabled.
  Future<int> adRewardsRemainingToday(String uid) async {
    final doc = await _userDoc(uid).get();
    return (maxAdRewardsPerDay - _adRewardsUsedToday(doc.data())).clamp(0, maxAdRewardsPerDay);
  }

  /// Grants [adRewardAmount] credits after a rewarded ad finishes playing
  /// (call this from the ad SDK's onUserEarnedReward callback, not before).
  /// This writes to the caller's OWN doc, so it's covered by the normal
  /// "you can edit your own profile" rule — no firestore.rules change needed.
  /// Returns false if today's daily cap is already reached.
  Future<bool> grantAdReward(String uid) async {
    final today = _todayKey();
    final ok = await _db.runTransaction<bool>((txn) async {
      final snap = await txn.get(_userDoc(uid));
      final used = _adRewardsUsedToday(snap.data());
      if (used >= maxAdRewardsPerDay) return false;
      final current = (snap.data()?['credits'] as num?)?.toInt() ?? 0;
      txn.update(_userDoc(uid), {
        'credits': current + adRewardAmount,
        'adRewardsDate': today,
        'adRewardsCountToday': used + 1,
      });
      return true;
    });
    if (ok) await _logTxn(uid, type: 'ad_reward', delta: adRewardAmount, label: 'Watched ad');
    return ok;
  }

  /// Spends [boostCost] credits to set `boostedUntil` [boostDuration] from
  /// now on the caller's own doc - Home ranks boosted profiles ahead of
  /// everyone else regardless of match score while still active. Returns
  /// false if the balance is too low.
  Future<bool> boostProfile(String uid) async {
    final ok = await spend(uid, amount: boostCost, type: 'boost', label: 'Profile boost (24h)');
    if (ok) {
      await _userDoc(uid).update({
        'boostedUntil': Timestamp.fromDate(DateTime.now().add(boostDuration)),
      });
    }
    return ok;
  }
}
