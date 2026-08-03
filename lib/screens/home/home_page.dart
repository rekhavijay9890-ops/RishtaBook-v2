import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/interest_service.dart';
import '../../services/credit_service.dart';
import '../../services/kundali_service.dart';
import '../../i18n/strings.dart';
import '../../i18n/language_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rb_section_label.dart';
import '../../widgets/wallet_strip.dart';
import '../../widgets/match_card.dart';
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
  final Set<String> _liked = {};

  static const _filterOptions = ['Religion', 'Caste', 'City', 'Age', 'Education', 'Manglik'];

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
            color: AppColors.headerBg,
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
                                  TextSpan(text: 'Book', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.saffron, letterSpacing: -0.5)),
                                ]),
                              ),
                              Text(context.t('app.tagline'), style: const TextStyle(fontSize: 10, color: AppColors.ghost)),
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
                        Text(context.t('home.searchHint'), style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
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
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _profileService.allProfilesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
                    }
                    final profiles = (snapshot.data?.docs ?? [])
                        .where((doc) => doc.id != uid)
                        .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
                        .toList();
                    if (profiles.isEmpty) {
                      return Center(child: Text(context.t('home.noProfiles'), style: const TextStyle(color: AppColors.muted)));
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        StreamBuilder<int>(
                          stream: _creditService.creditsStream(uid),
                          builder: (context, creditSnap) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: WalletStrip(credits: creditSnap.data ?? 0, onTap: () => Navigator.pushNamed(context, '/wallet')),
                            );
                          },
                        ),
                        RbSectionLabel(title: context.t('home.suggested')),
                        ...profiles.map((p) {
                          int? score;
                          if (me != null && me.hasKundaliDetails && p.hasKundaliDetails) {
                            score = KundaliService.compute(
                              boyRashi: me.isMale ? me.rashi : p.rashi,
                              boyNakshatra: me.isMale ? me.nakshatra : p.nakshatra,
                              girlRashi: me.isMale ? p.rashi : me.rashi,
                              girlNakshatra: me.isMale ? p.nakshatra : me.nakshatra,
                            ).total;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MatchCard(
                              name: p.fullName,
                              dob: p.dob,
                              job: p.occupation,
                              city: p.location,
                              caste: '${p.caste.isNotEmpty ? '${p.caste} · ' : ''}${p.religion}',
                              kundaliScore: score,
                              verified: p.isVerified,
                              initials: p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?',
                              accentColor: p.isFemale ? AppColors.rose : (p.isMale ? AppColors.teal : AppColors.saffron),
                              liked: _liked.contains(p.uid),
                              onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProfileScreen(profile: p))),
                              onKundali: () {
                                if (score == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('kundali.needDetails'))));
                                  return;
                                }
                                Navigator.pushNamed(context, '/kundali', arguments: {'otherUid': p.uid, 'otherName': p.fullName});
                              },
                              onChat: () => _openChatOrPrompt(context, p, uid),
                              onLike: () async {
                                setState(() => _liked.add(p.uid));
                                try {
                                  final exists = await InterestService().hasExistingInterest(uid, p.uid);
                                  if (!exists) {
                                    final myDoc = await _profileService.getUserProfile(uid);
                                    final myName = myDoc.data()?['fullName'] ?? 'Someone';
                                    await InterestService().sendInterest(fromUid: uid, fromName: myName, toUid: p.uid, toName: p.fullName);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.fullName} 💌'), backgroundColor: AppColors.success));
                                    }
                                  }
                                } catch (_) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('common.error'))));
                                }
                              },
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
            ),
          ),
        ],
      ),
    );
  }
}
