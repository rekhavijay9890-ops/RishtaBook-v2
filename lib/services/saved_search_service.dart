import 'package:cloud_firestore/cloud_firestore.dart';

/// A user's saved Search filter combinations - `users/{uid}/savedSearches`.
/// Stores the raw filter values (religion/category/gender/occupation/state/
/// motherTongue/income), reapplied verbatim when tapped.
class SavedSearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _searches(String uid) =>
      _db.collection('users').doc(uid).collection('savedSearches');

  Future<void> save(String uid, {required String name, required Map<String, dynamic> filters}) {
    return _searches(uid).add({
      'name': name,
      'filters': filters,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> stream(String uid) {
    return _searches(uid).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> delete(String uid, String searchId) {
    return _searches(uid).doc(searchId).delete();
  }
}
