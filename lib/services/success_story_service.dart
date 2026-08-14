import 'package:cloud_firestore/cloud_firestore.dart';

/// "Success Stories" shown on Home - social proof that real couples met
/// through the app. Two collections, mirroring the manualTopups
/// submit-then-admin-approves pattern:
///
/// - `pendingSuccessStories`: any user can submit their own story here.
///   Submitting never makes it public by itself.
/// - `successStories`: the live, publicly-shown list. Only ever written by
///   [approve] (which copies a pending submission across) or [addStory]
///   (the admin adding one directly, no user submission involved) - never
///   by a user directly.
class SuccessStoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _stories => _db.collection('successStories');
  CollectionReference<Map<String, dynamic>> get _pending => _db.collection('pendingSuccessStories');

  Stream<QuerySnapshot<Map<String, dynamic>>> storiesStream() {
    return _stories.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addStory({
    required String names,
    required String quote,
    String weddingDate = '',
    String photoUrl = '',
  }) {
    return _stories.add({
      'names': names,
      'quote': quote,
      'weddingDate': weddingDate,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStory(String storyId) {
    return _stories.doc(storyId).delete();
  }

  /// A user sharing their own story - goes into the review queue, not
  /// straight onto Home. [uid] is who submitted it, for `myPendingStream`
  /// and so an admin can see who's behind a submission.
  Future<void> submitStory(
    String uid, {
    required String names,
    required String quote,
    String weddingDate = '',
    String photoUrl = '',
  }) {
    return _pending.add({
      'uid': uid,
      'names': names,
      'quote': quote,
      'weddingDate': weddingDate,
      'photoUrl': photoUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myPendingStream(String uid) {
    return _pending.where('uid', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingReviewStream() {
    return _pending.where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).snapshots();
  }

  /// Copies a pending submission into the live, public collection and
  /// marks it approved - this is the only path a user-submitted story can
  /// reach Home through.
  Future<void> approve(String pendingId, {
    required String names,
    required String quote,
    required String weddingDate,
    required String photoUrl,
  }) async {
    final batch = _db.batch();
    batch.set(_stories.doc(), {
      'names': names,
      'quote': quote,
      'weddingDate': weddingDate,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_pending.doc(pendingId), {'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  Future<void> reject(String pendingId) {
    return _pending.doc(pendingId).update({'status': 'rejected', 'reviewedAt': FieldValue.serverTimestamp()});
  }
}
