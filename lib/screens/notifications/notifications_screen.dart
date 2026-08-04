import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

/// Full list of every in-app notification (credit added, profile viewed,
/// new message, interest received/accepted) for the signed-in user, newest
/// first. Unread ones are highlighted; tapping one marks it read.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'credit':
        return Icons.account_balance_wallet_outlined;
      case 'profile_view':
        return Icons.visibility_outlined;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'interest_received':
      case 'interest_accepted':
        return Icons.favorite_border_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'credit':
        return AppColors.gold;
      case 'profile_view':
        return AppColors.teal;
      case 'message':
        return AppColors.saffron;
      case 'interest_received':
      case 'interest_accepted':
        return AppColors.rose;
      default:
        return AppColors.muted;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'अभी / now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}मि / ${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}घं / ${diff.inHours}h';
    return '${diff.inDays}दिन / ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';
    final notificationService = NotificationService();

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text("सूचनाएं / Notifications"),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => notificationService.markAllRead(uid),
            child: const Text("सब पढ़ा हुआ / Mark all read", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationService.notificationsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.ghost),
                const SizedBox(height: 10),
                const Text("अभी कोई सूचना नहीं / No notifications yet", style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final type = data['type'] as String? ?? '';
              final title = data['title'] as String? ?? '';
              final body = data['body'] as String? ?? '';
              final read = data['read'] == true;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final color = _colorFor(type);

              return GestureDetector(
                onTap: () {
                  if (!read) notificationService.markRead(uid, doc.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: read ? AppColors.cardBg : color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: read ? AppColors.borderColor : color.withOpacity(0.3)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
                      child: Icon(_iconFor(type), color: color, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: TextStyle(fontSize: 13.5, fontWeight: read ? FontWeight.w600 : FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(body, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_timeAgo(createdAt), style: const TextStyle(fontSize: 10, color: AppColors.ghost)),
                      if (!read) ...[
                        const SizedBox(height: 6),
                        Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                      ],
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
