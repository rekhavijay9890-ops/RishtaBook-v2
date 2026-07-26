import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/interest.dart';
import '../../../services/auth_service.dart';
import '../../../services/interest_service.dart';
import '../../../services/profile_service.dart';
import '../../chat/chat_screen.dart';

import '../../../theme/app_theme.dart';

const Color kBrandColor = AppColors.primary;

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final interestService = InterestService();
    final uid = authService.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: interestService.matchesStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBrandColor));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Abhi tak koi match nahi hua hai.\nJab dono taraf se interest accept hoga, chat yahan shuru hogi.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final matches = snapshot.data!.docs.map((doc) => MatchRecord.fromDoc(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            final otherUid = match.otherUid(uid);

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: ProfileService().getUserProfile(otherUid),
              builder: (context, profileSnapshot) {
                final name = profileSnapshot.data?.data()?['fullName'] ?? 'Loading...';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: kBrandColor, child: Icon(Icons.favorite, color: Colors.white)),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      match.lastMessage.isEmpty ? "Baat shuru karein!" : match.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          matchId: match.id,
                          otherUserName: name,
                          currentUserId: uid,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
