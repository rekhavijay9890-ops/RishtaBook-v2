import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/kundali_service.dart';
import '../../i18n/strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/rb_avatar.dart';
import '../../widgets/rb_section_label.dart';
import '../../widgets/referral_cta_card.dart';
import '../auth/login_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  int _completionPct(UserProfile p) {
    final fields = [p.fullName, p.dob, p.gender, p.religion, p.caste, p.occupation, p.location, p.familyDetails, p.requirements];
    final filled = fields.where((f) => f.isNotEmpty && f != '--' && f != 'N/A').length;
    var pct = (filled / fields.length * 100).round();
    if (p.hasKundaliDetails) pct = (pct + 10).clamp(0, 100);
    return pct.clamp(0, 100);
  }

  void _openKundaliSheet(BuildContext context, String uid, UserProfile profile) {
    String rashi = profile.rashi.isNotEmpty ? profile.rashi : KundaliService.rashis.first;
    String nakshatra = profile.nakshatra.isNotEmpty ? profile.nakshatra : KundaliService.nakshatras.first;
    String manglik = profile.manglik == 'unknown' ? 'no' : profile.manglik;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.t('kundali.title'), style: AppText.headingLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: rashi,
              decoration: const InputDecoration(labelText: 'Rashi'),
              items: KundaliService.rashis.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setSheetState(() => rashi = v ?? rashi),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: nakshatra,
              decoration: const InputDecoration(labelText: 'Nakshatra'),
              items: KundaliService.nakshatras.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
              onChanged: (v) => setSheetState(() => nakshatra = v ?? nakshatra),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: manglik,
              decoration: InputDecoration(labelText: context.t('kundali.manglik')),
              items: [
                DropdownMenuItem(value: 'no', child: Text(context.t('kundali.no'))),
                DropdownMenuItem(value: 'yes', child: Text(context.t('kundali.yes'))),
              ],
              onChanged: (v) => setSheetState(() => manglik = v ?? manglik),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await ProfileService().updateUserProfile(uid, {'rashi': rashi, 'nakshatra': nakshatra, 'manglik': manglik});
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(context.t('common.save')),
            ),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final profileService = ProfileService();
    final user = authService.currentUser;
    if (user == null) return Center(child: Text(context.t('common.error')));

    Future<void> logout() async {
      await authService.signOut();
      if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: profileService.userProfileStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(context.t('profile.notFound')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: logout, child: Text(context.t('common.logout'))),
            ]));
          }
          final profile = UserProfile.fromMap(user.uid, snapshot.data!.data()!);
          final pct = _completionPct(profile);

          return ListView(
            children: [
              Container(
                color: AppColors.headerBg,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    child: Row(children: [
                      RbAvatar(initials: profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?', size: 64),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(profile.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('${profile.occupation} · ${profile.location}', style: const TextStyle(fontSize: 11, color: AppColors.ghost)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, children: [
                          if (profile.isVerified)
                            _headerChip(context.t('common.verified')),
                          _headerChip('$pct% ${context.isHindi ? "पूर्ण" : "complete"}'),
                        ]),
                      ])),
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  _verificationBanner(context, profileService, profile, user.uid),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(context.t('profile.completion'), style: AppText.headingSmall),
                        Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.saffron)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, backgroundColor: AppColors.pageBg, valueColor: const AlwaysStoppedAnimation(AppColors.saffron), minHeight: 6)),
                      const SizedBox(height: 6),
                      Text(context.t('profile.completionHint'), style: AppText.caption),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  RbSectionLabel(title: context.t('profile.aboutMe')),
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.6,
                    children: [
                      ['Religion', profile.religion], ['Caste', profile.caste],
                      ['Gotra', profile.gotra], ['Category', profile.category],
                    ].map((f) => Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderColor)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(f[0].toUpperCase(), style: AppText.label),
                        const SizedBox(height: 3),
                        Text(f[1].isEmpty ? context.t('common.notAvailable') : f[1], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink), overflow: TextOverflow.ellipsis),
                      ]),
                    )).toList(),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _openKundaliSheet(context, user.uid, profile),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.goldLight, AppColors.safLight]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('⭐', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(context.t('profile.kundaliDetails'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold)),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.gold),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          profile.hasKundaliDetails
                              ? '${profile.rashi} · ${profile.nakshatra}'
                              : context.t('kundali.needDetails'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8B6914)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const ReferralCtaCard(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(context.t('common.logout'), style: const TextStyle(color: Colors.white)),
                      onPressed: logout,
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
        child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
      );

  Widget _verificationBanner(BuildContext context, ProfileService profileService, UserProfile profile, String uid) {
    IconData icon; Color color; String title; String subtitle; Widget? action;
    if (profile.isVerified) {
      icon = Icons.verified; color = AppColors.teal; title = context.t('profile.verifyDone'); subtitle = '';
    } else if (profile.verificationStatus == 'pending') {
      icon = Icons.hourglass_top; color = AppColors.gold; title = context.t('profile.verifyPending'); subtitle = '';
    } else if (profile.verificationStatus == 'rejected') {
      icon = Icons.error_outline; color = AppColors.error; title = context.t('profile.verifyRejected'); subtitle = '';
      action = TextButton(onPressed: () => profileService.requestVerification(uid), child: Text(context.t('profile.requestVerify')));
    } else {
      icon = Icons.shield_outlined; color = AppColors.saffron; title = context.t('profile.verifyTitle'); subtitle = context.t('profile.verifyDesc');
      action = ElevatedButton(onPressed: () => profileService.requestVerification(uid), child: Text(context.t('profile.requestVerify')));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          if (action != null) action,
        ])),
      ]),
    );
  }
}
