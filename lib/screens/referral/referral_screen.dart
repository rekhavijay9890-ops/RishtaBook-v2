import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';
import '../../services/credit_service.dart';
import '../../services/profile_service.dart';
import '../../i18n/strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/rb_section_label.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});
  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _authService = AuthService();
  final _creditService = CreditService();
  final _profileService = ProfileService();
  final _mobileController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite(String uid, String referralCode, int bonus) async {
    final phone = _mobileController.text.trim();
    if (phone.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(CreditService.normalizePhone(phone))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('referral.invalidMobile'))));
      return;
    }
    setState(() => _sending = true);
    try {
      await _creditService.logManualInvite(uid, phone);
      _mobileController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('referral.inviteLogged')), backgroundColor: AppColors.success));
      }
      final message = context.t('referral.smsMessage', [referralCode]);
      final uri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': message});
      await launchUrl(uri);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('common.error'))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _shareLink(String referralCode) {
    Share.share(context.t('referral.smsMessage', [referralCode]));
  }

  /// Existing users who signed up before referral codes were friendly
  /// short strings only have the raw uid on record — generate and persist
  /// a real code for them the first time they open this screen.
  Future<String> _ensureReferralCode(String uid, Map<String, dynamic>? data) async {
    final existing = data?['referralCode'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    final code = CreditService.generateReferralCode();
    await _profileService.updateUserProfile(uid, {'referralCode': code});
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(children: [
        Container(
          width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              child: Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
                const SizedBox(width: 10),
                Text(context.t('referral.title'), style: AppText.headerTitle),
              ]),
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _profileService.userProfileStream(uid),
            builder: (context, profileSnap) {
              if (!profileSnap.hasData) return const Center(child: CircularProgressIndicator());
              return FutureBuilder<String>(
                future: _ensureReferralCode(uid, profileSnap.data!.data()),
                builder: (context, codeSnap) {
                  final referralCode = codeSnap.data ?? '…';
                  return FutureBuilder<int>(
                    future: _creditService.getReferralBonusAmount(),
                    builder: (context, bonusSnap) {
                      final bonus = bonusSnap.data ?? CreditService.referralBonus;
                      return ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.saffron, AppColors.safDark]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(context.t('referral.yourCode'), style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              SelectableText(referralCode, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                              const SizedBox(height: 10),
                              Text(context.t('referral.bonusInfo', [bonus]), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            ]),
                          ),
                  const SizedBox(height: 18),
                  RbSectionLabel(title: context.t('referral.addByMobile')),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(hintText: context.t('referral.mobileHint')),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _sending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.sms_outlined),
                      label: Text(context.t('referral.sendInvite')),
                      onPressed: _sending ? null : () => _sendInvite(uid, referralCode, bonus),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: Divider(color: AppColors.borderColor)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(context.t('referral.orShareLink'), style: AppText.caption)),
                    Expanded(child: Divider(color: AppColors.borderColor)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined),
                      label: Text(context.t('referral.shareLink')),
                      onPressed: () => _shareLink(referralCode),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RbSectionLabel(title: context.t('referral.yourInvites')),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _creditService.manualInvitesStream(uid),
                    builder: (context, inviteSnap) {
                      final manual = inviteSnap.data?.docs ?? [];
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _creditService.transactionsStream(uid, limit: 50),
                        builder: (context, txnSnap) {
                          final referralTxns = (txnSnap.data?.docs ?? []).where((d) => d.data()['type'] == 'referral').toList();
                          // Completed referrals that weren't tied to a manual invite
                          // (the friend used the shared code/link directly).
                          final untracked = (referralTxns.length - manual.where((d) => d.data()['status'] == 'completed').length).clamp(0, 1 << 30);

                          if (manual.isEmpty && referralTxns.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text(context.t('referral.noInvites'), style: AppText.caption)),
                            );
                          }

                          return Column(children: [
                            ...manual.map((d) {
                              final data = d.data();
                              final completed = data['status'] == 'completed';
                              return _inviteTile(
                                icon: completed ? Icons.check_circle : Icons.schedule,
                                iconColor: completed ? AppColors.teal : AppColors.gold,
                                title: data['phone'] ?? '',
                                status: completed ? context.t('referral.statusCompleted') : context.t('referral.statusInvited'),
                                statusColor: completed ? AppColors.teal : AppColors.gold,
                              );
                            }),
                            if (untracked > 0)
                              _inviteTile(
                                icon: Icons.check_circle,
                                iconColor: AppColors.teal,
                                title: context.t('referral.someoneJoined'),
                                status: context.t('referral.statusCompleted'),
                                statusColor: AppColors.teal,
                                count: untracked,
                              ),
                          ]);
                        },
                      );
                    },
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
        ),
      ]),
    );
  }

  Widget _inviteTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String status,
    required Color statusColor,
    int count = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(count > 1 ? '$title ×$count' : title, style: AppText.bodySmall)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
          child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
        ),
      ]),
    );
  }
}
