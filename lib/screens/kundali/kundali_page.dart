import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_profile.dart';
import '../../models/kundali.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/kundali_service.dart';
import '../../i18n/strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/rb_avatar.dart';
import '../../widgets/rb_section_label.dart';

class KundaliPage extends StatelessWidget {
  final String otherUid;
  final String otherName;
  const KundaliPage({super.key, required this.otherUid, required this.otherName});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';
    final profileService = ProfileService();

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
        future: Future.wait([profileService.getUserProfile(uid), profileService.getUserProfile(otherUid)]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(children: [_simpleHeader(context), const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.saffron)))]);
          }
          final me = UserProfile.fromMap(uid, snap.data![0].data() ?? {});
          final other = UserProfile.fromMap(otherUid, snap.data![1].data() ?? {});

          if (!me.hasKundaliDetails || !other.hasKundaliDetails) {
            return Column(children: [
              _simpleHeader(context),
              Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(context.t('kundali.needDetails'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted))))),
            ]);
          }

          final boy = me.isMale ? me : other;
          final girl = me.isMale ? other : me;
          final result = KundaliService.compute(boyRashi: boy.rashi, boyNakshatra: boy.nakshatra, girlRashi: girl.rashi, girlNakshatra: girl.nakshatra);

          return Column(children: [
            _header(context, me, other, result),
            Expanded(
              child: ListView(padding: const EdgeInsets.all(12), children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(context.t('kundali.overall'), style: AppText.headingSmall),
                      Text(_verdict(context, result), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _verdictColor(result))),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: result.total / result.maxTotal, backgroundColor: AppColors.pageBg, valueColor: AlwaysStoppedAnimation(_verdictColor(result)), minHeight: 8)),
                    const SizedBox(height: 6),
                    Text(context.t('kundali.outOf36', [result.total]), style: AppText.caption),
                  ]),
                ),
                const SizedBox(height: 12),
                RbSectionLabel(title: context.t('kundali.breakdown')),
                Container(
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
                  clipBehavior: Clip.hardEdge,
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      color: AppColors.goldLight,
                      child: Row(children: [
                        Expanded(child: Text(context.t('kundali.koot'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gold))),
                        SizedBox(width: 46, child: Text(context.t('kundali.score'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gold))),
                        SizedBox(width: 40, child: Text(context.t('kundali.max'), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gold))),
                      ]),
                    ),
                    ...result.koots.asMap().entries.map((e) {
                      final k = e.value;
                      final pct = k.score / k.max;
                      final color = pct == 1.0 ? AppColors.teal : (pct == 0.0 ? AppColors.error : AppColors.gold);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        color: e.key.isEven ? const Color(0xFFFDFAFC) : AppColors.cardBg,
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(k.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            const SizedBox(height: 3),
                            ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.pageBg, valueColor: AlwaysStoppedAnimation(color), minHeight: 3)),
                          ])),
                          SizedBox(width: 46, child: Text('${k.score}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color))),
                          SizedBox(width: 40, child: Text('${k.max}', textAlign: TextAlign.right, style: AppText.caption)),
                        ]),
                      );
                    }),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gold.withOpacity(0.3))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.t('kundali.disclaimerTitle'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gold)),
                    const SizedBox(height: 4),
                    Text(context.t('kundali.disclaimer'), style: const TextStyle(fontSize: 10, color: Color(0xFF8B6914), height: 1.6)),
                  ]),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  String _verdict(BuildContext context, GunaMilanResult r) {
    final ratio = r.total / r.maxTotal;
    if (ratio >= 0.6) return context.t('kundali.good');
    if (ratio >= 0.4) return context.t('kundali.average');
    return context.t('kundali.poor');
  }

  Color _verdictColor(GunaMilanResult r) {
    final ratio = r.total / r.maxTotal;
    if (ratio >= 0.6) return AppColors.teal;
    if (ratio >= 0.4) return AppColors.gold;
    return AppColors.error;
  }

  Widget _simpleHeader(BuildContext context) => Container(
        color: AppColors.headerBg,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Text(context.t('kundali.title'), style: AppText.headerTitle),
            ]),
          ),
        ),
      );

  Widget _header(BuildContext context, UserProfile me, UserProfile other, GunaMilanResult result) {
    return Container(
      color: AppColors.headerBg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          child: Column(children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Text(context.t('kundali.title'), style: AppText.headerTitle),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: Column(children: [
                RbAvatar(initials: me.fullName.isNotEmpty ? me.fullName[0].toUpperCase() : '?', size: 52),
                const SizedBox(height: 6),
                Text(me.fullName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
                Text('${me.rashi} · ${me.nakshatra}', style: const TextStyle(fontSize: 10, color: AppColors.ghost), overflow: TextOverflow.ellipsis),
              ])),
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.gold, AppColors.saffron]), borderRadius: BorderRadius.circular(14)),
                  child: RichText(text: TextSpan(children: [
                    TextSpan(text: '${result.total}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    TextSpan(text: '/${result.maxTotal}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ])),
                ),
                const SizedBox(height: 4),
                Text(context.t('kundali.gunMilan'), style: const TextStyle(fontSize: 9, color: AppColors.ghost, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ]),
              Expanded(child: Column(children: [
                RbAvatar(initials: other.fullName.isNotEmpty ? other.fullName[0].toUpperCase() : '?', size: 52, color: AppColors.teal),
                const SizedBox(height: 6),
                Text(other.fullName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
                Text('${other.rashi} · ${other.nakshatra}', style: const TextStyle(fontSize: 10, color: AppColors.ghost), overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ]),
        ),
      ),
    );
  }
}
