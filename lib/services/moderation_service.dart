import 'package:cloud_firestore/cloud_firestore.dart';

/// Block and report - the two concrete safety actions a user can take
/// against another profile. Block is a self-write (blockedUids array on
/// the blocker's own doc); a blocked person is filtered out of Home/
/// Search results for the blocker, but is NOT told they've been blocked
/// and can still be seen by the blocker on the reverse direction (a
/// documented simplification - true bidirectional hiding would need a
/// collection-group query across everyone's blockedUids, which doesn't
/// scale without a backend). Reports go into a moderation queue an admin
/// reviews from the Admin screen.
class ModerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports => _db.collection('reports');

  Future<void> blockUser(String myUid, String targetUid) {
    return _users.doc(myUid).update({'blockedUids': FieldValue.arrayUnion([targetUid])});
  }

  Future<void> unblockUser(String myUid, String targetUid) {
    return _users.doc(myUid).update({'blockedUids': FieldValue.arrayRemove([targetUid])});
  }

  Stream<List<String>> blockedUidsStream(String myUid) {
    return _users.doc(myUid).snapshots().map((doc) => List<String>.from(doc.data()?['blockedUids'] ?? const []));
  }

  Future<void> fileReport(String reporterUid, {required String reportedUid, required String reason, String? details}) {
    return _reports.add({
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason,
      'details': details ?? '',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> openReportsStream() {
    return _reports.where('status', isEqualTo: 'open').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> resolveReport(String reportId) {
    return _reports.doc(reportId).update({'status': 'resolved'});
  }
}
