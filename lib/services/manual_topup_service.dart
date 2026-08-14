import 'package:cloud_firestore/cloud_firestore.dart';

/// Manual UPI top-up requests - the active payment path while no automated
/// gateway is approved (Razorpay's business account got rejected; see
/// AppConfig.razorpayKeyId's doc comment). A user pays AppConfig.upiId
/// directly via their own UPI app, then submits the transaction reference
/// here. An admin verifies the payment actually landed and approves it
/// from the Admin screen - [approve] is the ONLY path that grants credits.
/// [submitRequest] just files a claim; it never touches the balance.
class ManualTopupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests => _db.collection('manualTopups');

  Future<void> submitRequest(
    String uid, {
    required int amountRupees,
    required int credits,
    required String utr,
  }) {
    return _requests.add({
      'uid': uid,
      'amountRupees': amountRupees,
      'credits': credits,
      'utr': utr,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myRequestsStream(String uid) {
    return _requests.where('uid', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingRequestsStream() {
    return _requests.where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).snapshots();
  }

  /// Grants the credits, logs the matching transaction ledger entry, AND
  /// marks the request approved, all in one batch - so a crash mid-approval
  /// can never leave credits granted without a matching ledger entry (or a
  /// request stuck "pending" after its credits already landed).
  Future<void> approve(
    String requestId, {
    required String uid,
    required int credits,
    required int amountRupees,
  }) {
    final batch = _db.batch();
    batch.update(_requests.doc(requestId), {'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()});
    batch.update(_db.collection('users').doc(uid), {'credits': FieldValue.increment(credits)});
    batch.set(_db.collection('users').doc(uid).collection('transactions').doc(), {
      'type': 'purchase',
      'delta': credits,
      'label': '₹$amountRupees UPI top-up',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  Future<void> reject(String requestId) {
    return _requests.doc(requestId).update({'status': 'rejected', 'reviewedAt': FieldValue.serverTimestamp()});
  }
}
