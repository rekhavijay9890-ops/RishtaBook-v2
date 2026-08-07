import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/interest.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/interest_service.dart';
import '../../services/profile_service.dart';
import '../../i18n/strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/rb_avatar.dart';
import '../../widgets/rb_badge.dart';
import '../profile/view_profile_screen.dart';

class InterestsPage extends StatefulWidget {
  const InterestsPage({super.key});
  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  String _tab = 'received';
  final _authService = AuthService();
  final _interestService = InterestService();

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: Text(context.t('interests.title'), style: AppText.headerTitle),
                  ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _interestService.receivedInterestsStream(uid),
                    builder: (context, recvSnap) {
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _interestService.sentInterestsStream(uid),
                        builder: (context, sentSnap) {
                          final recvCount = recvSnap.data?.docs.length ?? 0;
                          final sentCount = sentSnap.data?.docs.length ?? 0;
                          return Row(
                            children: ['received', 'sent'].map((t) {
                              final on = _tab == t;
                              final label = t == 'received'
                                  ? '${context.t('interests.received')} ($recvCount)'
                                  : '${context.t('interests.sent')} ($sentCount)';
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _tab = t),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: on ? AppColors.saffron : Colors.transparent, width: 3))),
                                    child: Text(label, textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 12, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: on ? Colors.white : AppColors.ghost)),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _tab == 'received' ? _ReceivedList(uid: uid) : _SentList(uid: uid)),
        ],
      ),
    );
  }
}

class _ReceivedList extends StatelessWidget {
  final String uid;
  const _ReceivedList({required this.uid});

  @override
  Widget build(BuildContext context) {
    final interestService = InterestService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: interestService.receivedInterestsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
        }
        final interests = (snapshot.data?.docs ?? []).map((d) => Interest.fromDoc(d)).toList();
        if (interests.isEmpty) {
          return Center(child: Text(context.t('interests.noneReceived'), style: const TextStyle(color: AppColors.muted)));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          itemCount: interests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final interest = interests[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                InkWell(
                  onTap: () async {
                    final doc = await ProfileService().getUserProfile(interest.fromUid);
                    if (!context.mounted || !doc.exists) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProfileScreen(profile: UserProfile.fromMap(doc.id, doc.data()!))));
                  },
                  child: Row(children: [
                    RbAvatar(initials: interest.fromName.isNotEmpty ? interest.fromName[0].toUpperCase() : '?', size: 44),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${interest.fromName}', style: AppText.headingMedium)),
                    const Icon(Icons.chevron_right, color: AppColors.ghost),
                  ]),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                      onPressed: () => interestService.respondToInterest(interestId: interest.id, fromUid: interest.fromUid, toUid: interest.toUid, accept: false),
                      child: Text(context.t('common.reject')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                      onPressed: () => interestService.respondToInterest(interestId: interest.id, fromUid: interest.fromUid, toUid: interest.toUid, accept: true),
                      child: Text(context.t('common.accept')),
                    ),
                  ),
                ]),
              ]),
            );
          },
        );
      },
    );
  }
}

class _SentList extends StatelessWidget {
  final String uid;
  const _SentList({required this.uid});

  @override
  Widget build(BuildContext context) {
    final interestService = InterestService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: interestService.sentInterestsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
        }
        final interests = (snapshot.data?.docs ?? []).map((d) => Interest.fromDoc(d)).toList();
        if (interests.isEmpty) {
          return Center(child: Text(context.t('interests.noneSent'), style: const TextStyle(color: AppColors.muted)));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          itemCount: interests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final interest = interests[i];
            final color = interest.status == 'accepted' ? AppColors.teal : (interest.status == 'rejected' ? AppColors.rose : AppColors.gold);
            final label = interest.status == 'accepted'
                ? context.t('interests.accepted')
                : (interest.status == 'rejected' ? context.t('interests.rejected') : context.t('interests.pending'));
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
              child: Row(children: [
                RbAvatar(initials: interest.toName.isNotEmpty ? interest.toName[0].toUpperCase() : '?', size: 44, color: AppColors.saffron),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(interest.toName, style: AppText.headingMedium),
                  const SizedBox(height: 4),
                  RbBadge(text: label, color: color),
                ])),
              ]),
            );
          },
        );
      },
    );
  }
}
