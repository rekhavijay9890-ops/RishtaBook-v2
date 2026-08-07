import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/interest.dart';
import '../../services/auth_service.dart';
import '../../services/interest_service.dart';
import '../../services/profile_service.dart';
import '../../i18n/strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/rb_avatar.dart';

class ChatsListPage extends StatelessWidget {
  const ChatsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';
    final interestService = InterestService();

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Text(context.t('chats.title'), style: AppText.headerTitle),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: interestService.matchesStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
                }
                final matches = (snapshot.data?.docs ?? []).map((d) => MatchRecord.fromDoc(d)).toList();
                if (matches.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(context.t('chats.empty'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final match = matches[i];
                    final otherUid = match.otherUid(uid);
                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: ProfileService().getUserProfile(otherUid),
                      builder: (context, profileSnap) {
                        final name = profileSnap.data?.data()?['fullName'] ?? '...';
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: RbAvatar(initials: name.isNotEmpty ? name[0].toUpperCase() : '?', size: 46),
                            title: Text(name, style: AppText.headingMedium),
                            subtitle: Text(match.lastMessage.isEmpty ? context.t('chats.startChat') : match.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySmall),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.ghost),
                            onTap: () => Navigator.pushNamed(context, '/chat', arguments: {
                              'matchId': match.id,
                              'otherUserName': name,
                              'currentUserId': uid,
                            }),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
