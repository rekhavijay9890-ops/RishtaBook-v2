import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin-curated "Success Stories" shown on Home - social proof that real
/// couples met through the app. Purely admin-authored (mirrors the
/// `manualTopups`/`astrologerRequests` admin-only-write pattern): a user
/// never creates or edits one of these, only the admin from the Admin
/// screen's Success Stories tab.
class SuccessStoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _stories => _db.collection('successStories');

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
}
