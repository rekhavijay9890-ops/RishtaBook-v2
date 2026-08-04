import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../services/profile_service.dart';
import '../../i18n/strings.dart';
import '../profile/complete_profile_screen.dart';

/// Shown once, right after [BasicDetailsScreen] — complete the extended
/// profile now, or skip and do it later from the Profile tab. Either
/// choice sets `onboardingChoiceMade`, so AuthGate never shows this again.
class ProfileChoiceScreen extends StatefulWidget {
  final String uid;
  final String fullName;
  const ProfileChoiceScreen({super.key, required this.uid, required this.fullName});

  @override
  State<ProfileChoiceScreen> createState() => _ProfileChoiceScreenState();
}

class _ProfileChoiceScreenState extends State<ProfileChoiceScreen> {
  final _profileService = ProfileService();
  bool _busy = false;

  Future<void> _markChoiceMade() {
    return _profileService.updateUserProfile(widget.uid, {'onboardingChoiceMade': true});
  }

  Future<void> _skip() async {
    setState(() => _busy = true);
    await _markChoiceMade();
    // AuthGate reacts to the profile doc changing on its own.
  }

  Future<void> _completeNow() async {
    setState(() => _busy = true);
    await _markChoiceMade();
    if (mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => CompleteProfileScreen(uid: widget.uid)));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.t('profileChoice.welcome', [widget.fullName]),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(context.t('profileChoice.accountCreated'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
              ]),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _busy ? null : _completeNow,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.goldLight, AppColors.safLight]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.saffron),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.t('profileChoice.completeTitle'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(context.t('profileChoice.completeDesc'), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.saffron), borderRadius: BorderRadius.circular(100)),
                      child: Text(context.t('profileChoice.recommended'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.saffron)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _busy ? null : _skip,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.t('profileChoice.skipTitle'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(context.t('profileChoice.skipDesc'), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  ]),
                ),
              ),
              if (_busy) const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: CircularProgressIndicator(color: AppColors.saffron))),
            ],
          ),
        ),
      ),
    );
  }
}
