import 'package:cloud_firestore/cloud_firestore.dart';

/// Astrologer consultation requests - a callback-request queue, not a
/// live booking/scheduling system (there's no astrologer network or
/// calendar backend in this app). A user submits their contact details +
/// preferred time; an admin follows up manually from the Admin screen and
/// marks it contacted. Deliberately simple rather than faking real-time
/// availability that doesn't exist.
class AstrologerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests => _db.collection('astrologerRequests');

  Future<void> requestConsultation(String uid, {
    required String name,
    required String phone,
    required String preferredTime,
    String? notes,
  }) {
    return _requests.add({
      'uid': uid,
      'name': name,
      'phone': phone,
      'preferredTime': preferredTime,
      'notes': notes ?? '',
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

  Future<void> markContacted(String requestId) {
    return _requests.doc(requestId).update({'status': 'contacted'});
  }
}
