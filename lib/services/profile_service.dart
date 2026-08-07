import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Reads/writes for the `users` collection - registration data,
/// profile browsing, and the verification status fields.
class ProfileService {
  static const int maxPhotos = 10;

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

  /// Resolves a short referral code (see CreditService.generateReferralCode)
  /// to the referrer's uid. Returns null if no user has that code.
  Future<String?> findUidByReferralCode(String code) async {
    final q = await _users.where('referralCode', isEqualTo: code).limit(1).get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id;
  }

  /// Bounded version of [allProfilesStream] for the Home tab's "suggested
  /// matches" list, which only ever shows a handful of cards - fetching
  /// every field of every user in the whole app on every Home render (what
  /// allProfilesStream does, unbounded) is the single biggest contributor
  /// to a slow first load right after sign-in, especially over a weak
  /// connection. Search still uses allProfilesStream since it genuinely
  /// needs to filter across everyone.
  Stream<QuerySnapshot<Map<String, dynamic>>> suggestedProfilesStream({int limit = 20}) {
    return _users.limit(limit).snapshots();
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

  /// Uploads [file] to this user's own photo folder in Supabase Storage
  /// (see AppConfig doc - Storage-only swap off Firebase Storage) and
  /// appends its public URL to `photoUrls` on the user doc. Throws if the
  /// user already has [maxPhotos] photos - callers should disable the
  /// "add" affordance at that point, this is the hard backstop.
  Future<String> uploadProfilePhoto(String uid, File file) async {
    final current = await currentPhotoUrls(uid);
    if (current.length >= maxPhotos) {
      throw StateError('Maximum $maxPhotos photos reached');
    }
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storage = Supabase.instance.client.storage.from(AppConfig.supabasePhotosBucket);
    await storage.upload(path, file);
    final url = storage.getPublicUrl(path);
    await _users.doc(uid).set({'photoUrls': FieldValue.arrayUnion([url])}, SetOptions(merge: true));
    return url;
  }

  Future<List<String>> currentPhotoUrls(String uid) async {
    final doc = await _users.doc(uid).get();
    return List<String>.from(doc.data()?['photoUrls'] ?? const []);
  }

  /// Removes [url] from both Supabase Storage and the user's `photoUrls`
  /// array. Best-effort on the Storage delete - an already-missing object
  /// (e.g. deleted twice, or a URL from before the Supabase swap) shouldn't
  /// block clearing it from Firestore.
  Future<void> deleteProfilePhoto(String uid, String url) async {
    try {
      const marker = '/object/public/${AppConfig.supabasePhotosBucket}/';
      final idx = url.indexOf(marker);
      if (idx != -1) {
        final path = url.substring(idx + marker.length);
        await Supabase.instance.client.storage.from(AppConfig.supabasePhotosBucket).remove([path]);
      }
    } catch (_) {}
    await _users.doc(uid).update({'photoUrls': FieldValue.arrayRemove([url])});
  }

  /// Best-effort cleanup of everything this app itself owns for [uid]
  /// before the caller deletes the Firebase Auth account: Supabase Storage
  /// photos, then the Firestore `users/{uid}` doc (subcollections like
  /// transactions/notifications are left behind as orphaned data - Firestore
  /// doesn't cascade-delete, and there's no Cloud Functions job in this
  /// project to sweep them; harmless since nothing reads them once the
  /// parent doc and the Auth account are both gone).
  Future<void> deleteAllUserData(String uid) async {
    final urls = await currentPhotoUrls(uid);
    for (final url in urls) {
      try {
        const marker = '/object/public/${AppConfig.supabasePhotosBucket}/';
        final idx = url.indexOf(marker);
        if (idx != -1) {
          final path = url.substring(idx + marker.length);
          await Supabase.instance.client.storage.from(AppConfig.supabasePhotosBucket).remove([path]);
        }
      } catch (_) {}
    }
    await _users.doc(uid).delete();
  }

  /// Reorders so [url] becomes the first (primary/display) photo.
  Future<void> setPrimaryPhoto(String uid, String url) async {
    final urls = await currentPhotoUrls(uid);
    if (!urls.contains(url)) return;
    urls
      ..remove(url)
      ..insert(0, url);
    await _users.doc(uid).update({'photoUrls': urls});
  }
}
