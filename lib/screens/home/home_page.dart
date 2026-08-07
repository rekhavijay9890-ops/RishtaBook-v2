import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../models/partner_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/interest_service.dart';
import '../../services/chat_service.dart';
import '../../services/credit_service.dart';
import '../../services/kundali_service.dart';
import '../../services/matchmaking_service.dart';
import '../../i18n/strings.dart';
import '../../i18n/language_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rb_section_label.dart';
import '../../widgets/rb_stat_strip.dart';
import '../../widgets/top_matches_carousel.dart';
import '../../widgets/match_card.dart';
import '../../widgets/referral_cta_card.dart';
import '../profile/view_profile_screen.dart';
import '../root_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final CreditService _creditService = CreditService();
  final InterestService _interestService = InterestService();
  final ChatService _chatService = ChatService();
  final Set<String> _liked = {};

  static const _filterOptions = ['Religion', 'Caste', 'City', 'Age', 'Education', 'Manglik'];

  Future<void> _sendInterest(BuildContext context, String myUid, UserProfile p) async {
    setState(() => _liked.add(p.uid));
    try {
      final exists = await InterestService().hasExistingInterest(myUid, p.uid);
      if (!exists) {
        final myDoc = await _profileService.getUserProfile(myUid);
        final myName = myDoc.data()?['fullName'] ?? 'Someone';
        await InterestService().sendInterest(fromUid: myUid, fromName: myName, toUid: p.uid, toName: p.fullName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.fullName} 💌'), backgroundColor: AppColors.success));
        }
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('common.error'))));
    }
  }

  Future<void> _openChatOrPrompt(BuildContext context, UserProfile profile, String myUid) async {
    final matchId = InterestService.matchIdFor(myUid, profile.uid);
    final matchDoc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
    if (!context.mounted) return;
    if (!matchDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.isHindi
              ? 'रुचि स्वीकृत होने के बाद ही बातचीत खुलेगी।'
              : 'Chat opens once your interest is mutually accepted.')));
      return;
    }
    final otherName = profile.fullName;
    Navigator.pushNamed(context, '/chat', arguments: {
      'matchId': matchId,
      'otherUserName': otherName,
      'currentUserId': myUid,
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid ?? '';
    final isHindi = context.isHindi;

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
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: const TextSpan(children: [
                                  TextSpan(text: 'Rishta', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                                  TextSpan(text: 'Book', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFFD877), letterSpacing: -0.5)),
                                ]),
                              ),
                              Text(context.t('app.tagline'), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.read<LanguageController>().toggle(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                            child: Text(isHindi ? 'हिं / EN' : 'EN / हिं', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const RootHeaderActions(),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(children: [
                        const Text('🔍', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 10),
                        Text(context.t('home.searchHint'), style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _profileService.userProfileStream(uid),
              builder: (context, meSnap) {
                final me = meSnap.data?.data() != null ? UserProfile.fromMap(uid, meSnap.data!.data()!) : null;
                final myPrefs = PartnerPreferences.fromMap(meSnap.data?.data()?['preferences'] as Map<String, dynamic>?);
                final blockedUids = me?.blockedUids ?? const [];
                return StreamBuilder<Set<String>>(
                  stream: InterestService().matchedUidsStream(uid),
                  builder: (context, matchedSnap) {
                    final matchedUids = matchedSnap.data ?? const <String>{};
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _profileService.suggestedProfilesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
                    }
                    final profiles = (snapshot.data?.docs ?? [])
                        .where((doc) => doc.id != uid && !blockedUids.contains(doc.id))
                        .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
                        .toList();
                    if (profiles.isEmpty) {
                      return Center(child: Text(context.t('home.noProfiles'), style: const TextStyle(color: AppColors.muted)));
                    }
                    // Rank by MatchmakingService score against the viewer's own
                    // partner preferences - the actual "matchmaking engine",
                    // computed client-side since the candidate pool here is
                    // already bounded (see suggestedProfilesStream). Boosted
                    // profiles (Wallet -> Boost) always rank first while active.
                    int kundaliFor(UserProfile p) {
                      if (me == null || !me.hasKundaliDetails || !p.hasKundaliDetails) return -1;
                      return KundaliService.compute(
                        boyRashi: me.isMale ? me.rashi : p.rashi,
                        boyNakshatra: me.isMale ? me.nakshatra : p.nakshatra,
                        girlRashi: me.isMale ? p.rashi : me.rashi,
                        girlNakshatra: me.isMale ? p.nakshatra : me.nakshatra,
                      ).total;
                    }
                    profiles.sort((a, b) {
                      if (a.isBoosted != b.isBoosted) return a.isBoosted ? -1 : 1;
                      final ka = kundaliFor(a), kb = kundaliFor(b);
                      final sa = MatchmakingService.score(a, myPrefs, kundaliScore: ka >= 0 ? ka : null);
                      final sb = MatchmakingService.score(b, myPrefs, kundaliScore: kb >= 0 ? kb : null);
                      return sb.compareTo(sa);
                    });
                    final topEntries = profiles.take(5).toList();
                    final restProfiles = profiles.skip(5).toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        StreamBuilder<int>(
                          stream: _creditService.creditsStream(uid),
                          builder: (context, creditSnap) {
                            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: _interestService.receivedInterestsStream(uid),
                              builder: (context, interestSnap) {
                                return StreamBuilder<int>(
                                  stream: _chatService.totalUnreadStream(uid),
                                  builder: (context, unreadSnap) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: RbStatStrip(stats: [
                                        RbStat(
                                          value: '${interestSnap.data?.docs.length ?? 0}',
                                          label: context.t('home.stat.interests'),
                                          onTap: () => Navigator.pushNamed(context, '/root'),
                                        ),
                                        RbStat(
                                          value: '${creditSnap.data ?? 0}',
                                          label: context.t('home.stat.credits'),
                                          onTap: () => Navigator.pushNamed(context, '/wallet'),
                                        ),
                                        RbStat(
                                          value: '${unreadSnap.data ?? 0}',
                                          label: context.t('home.stat.unread'),
                                          onTap: () => Navigator.pushNamed(context, '/root'),
                                        ),
                                        RbStat(
                                          value: (me?.isBoosted ?? false) ? '🚀' : '—',
                                          label: (me?.isBoosted ?? false) ? context.t('home.stat.boostOn') : context.t('home.stat.boostOff'),
                                          onTap: () => Navigator.pushNamed(context, '/wallet'),
                                        ),
                                      ]),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        const Padding(padding: EdgeInsets.only(bottom: 18), child: ReferralCtaCard()),
                        if (topEntries.isNotEmpty) ...[
                          RbSectionLabel(title: context.t('home.topMatches')),
                          const SizedBox(height: 4),
                          TopMatchesCarousel(
                            entries: topEntries.map((p) {
                              final k = kundaliFor(p);
                              final score = k >= 0 ? k : null;
                              final matchPct = MatchmakingService.score(p, myPrefs, kundaliScore: score);
                              return TopMatchEntry(
                                profile: p,
                                matchScorePct: matchPct,
                                blurred: p.photosPrivate && !matchedUids.contains(p.uid),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProfileScreen(profile: p, matchScorePct: matchPct, kundaliScore: score))),
                                onSend: _liked.contains(p.uid) ? null : () => _sendInterest(context, uid, p),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                        ],
                        RbSectionLabel(title: restProfiles.isEmpty ? context.t('home.suggested') : context.t('home.moreMatches')),
                        ...(restProfiles.isEmpty ? topEntries : restProfiles).map((p) {
                          final k = kundaliFor(p);
                          final score = k >= 0 ? k : null;
                          final matchPct = MatchmakingService.score(p, myPrefs, kundaliScore: score);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MatchCard(
                              name: p.fullName,
                              dob: p.dob,
                              job: p.occupation,
                              city: p.location,
                              caste: '${p.caste.isNotEmpty ? '${p.caste} · ' : ''}${p.religion}',
                              kundaliScore: score,
                              matchScorePct: matchPct,
                              blurred: p.photosPrivate && !matchedUids.contains(p.uid),
                              boosted: p.isBoosted,
                              verified: p.isVerified,
                              initials: p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?',
                              photoUrl: p.primaryPhotoUrl,
                              accentColor: p.isFemale ? AppColors.rose : (p.isMale ? AppColors.teal : AppColors.saffron),
                              liked: _liked.contains(p.uid),
                              onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProfileScreen(profile: p, matchScorePct: matchPct, kundaliScore: score))),
                              onKundali: () {
                                if (score == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('kundali.needDetails'))));
                                  return;
                                }
                                Navigator.pushNamed(context, '/kundali', arguments: {'otherUid': p.uid, 'otherName': p.fullName});
                              },
                              onChat: () => _openChatOrPrompt(context, p, uid),
                              onLike: () => _sendInterest(context, uid, p),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        RbSectionLabel(title: context.t('home.filterBy')),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: _filterOptions.asMap().entries.map((e) {
                            final active = e.key == 0;
                            return GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/search'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.saffron : AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: active ? AppColors.saffron : AppColors.borderColor, width: 1.5),
                                ),
                                child: Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.muted)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
