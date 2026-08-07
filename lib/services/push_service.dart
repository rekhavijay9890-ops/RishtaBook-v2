import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Real device push notifications (lock screen / notification tray), on
/// top of NotificationService's in-app notification list.
///
/// Sending a push normally needs server-side code holding a Google
/// service-account credential (a Firebase Cloud Function calling the FCM
/// API) - that requires the Blaze billing plan, same wall as Storage. This
/// calls a Supabase Edge Function instead (see supabase/functions/send-push)
/// which holds that credential server-side on Supabase's free tier.
class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Requests notification permission and stores this device's FCM token
  /// on the user doc, keeping it updated if it ever rotates. Safe to call
  /// every app start - a no-op if permission was already granted/denied.
  Future<void> registerToken(String uid) async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(uid, token);
      _messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));
    } catch (_) {
      // Permission denied or unsupported (e.g. desktop) - the app still
      // works fine on the in-app notification list alone.
    }
  }

  Future<void> _saveToken(String uid, String token) {
    return _db.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
  }

  /// Looks up [targetUid]'s current FCM token and asks the Edge Function to
  /// push [title]/[body] to it. Best-effort and silent on failure (no
  /// token yet, function unreachable, etc.) - the in-app notification list
  /// (NotificationService) is always written regardless, so nothing is
  /// ever lost, this is purely the "also buzz their phone" layer on top.
  Future<void> sendPush(String targetUid, {required String title, required String body}) async {
    try {
      final doc = await _db.collection('users').doc(targetUid).get();
      final token = doc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;

      await http.post(
        Uri.parse(AppConfig.supabasePushFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
        body: jsonEncode({'token': token, 'title': title, 'body': body}),
      );
    } catch (_) {}
  }
}
