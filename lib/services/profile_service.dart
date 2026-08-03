import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads/writes for the `users` collection - registration data,
/// profile browsing, and the verification status fields.
class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Future<void> createUserProfile(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).set(data);
  }

  /// Merges [data] into an existing profile — used both for post-signup
  /// edits and for completing a profile that was only partially created
  /// (e.g. a first Google sign-in, which only sets fullName/email).
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(String uid) {
    return _users.doc(uid).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _users.doc(uid).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> allProfilesStream() {
    return _users.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> recentJoinsStream({int limit = 5}) {
    return _users.orderBy('createdAt', descending: true).limit(limit).snapshots();
  }

  /// Sets this user's verificationStatus to 'pending'. An admin later
  /// approves/rejects it from the Admin screen.
  Future<void> requestVerification(String uid) {
    return _users.doc(uid).update({'verificationStatus': 'pending'});
  }

  Future<void> setVerificationDecision(String uid, bool approve) {
    return _users.doc(uid).update({
      'verificationStatus': approve ? 'approved' : 'rejected',
      'isVerified': approve,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingVerificationsStream() {
    return _users.where('verificationStatus', isEqualTo: 'pending').snapshots();
  }
}
