import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../widgets/video_background.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/credit_service.dart';
import '../../i18n/language_controller.dart';
import '../../i18n/strings.dart';
import 'phone_auth_screen.dart';
import 'email_auth_screen.dart';

/// The clean, standard sign-in entry point: Google or mobile number, with
/// a small "sign in with email" fallback for accounts created before this
/// screen existed. Replaces the old single giant login/signup form.
class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _creditService = CreditService();
  bool _loading = false;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final uid = userCredential.user!.uid;
        await _profileService.createUserProfile(uid, {
          'uid': uid,
          'fullName': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'verificationStatus': 'none',
          'isVerified': false,
          // NOT 'credits: signupBonus' here - grantSignupBonus below both
          // credits the balance AND logs the matching transaction ledger
          // entry; setting it here too silently doubled every new user's
          // welcome bonus and left the balance out of sync with their
          // visible transaction history.
          'credits': 0,
          'createdAt': DateTime.now(),
          'referralCode': CreditService.generateReferralCode(),
        });
        await _creditService.grantSignupBonus(uid);
      }
      // AuthGate reacts to the auth state + profile doc changing on its
      // own - no explicit navigation needed here.
    } catch (e) {
      if (mounted) _showSnack(context.t('authLanding.googleFailed'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.headerBg,
      // Full-bleed video: no header band, no scallop clip. The video fills
      // the whole screen and every control (language toggle, sign-in
      // buttons, footer) is overlaid directly on top of it.
      body: VideoBackground(
        asset: 'assets/video/signin_bg.mp4',
        child: SafeArea(
          // A plain Column directly under SafeArea (not wrapped in a
          // ScrollView) so Spacer gets the bounded height it needs from
          // the Scaffold - nesting it inside SingleChildScrollView gives
          // Spacer an unbounded height and makes every widget below it
          // fail to render (video shows, everything else silently vanishes).
          // This screen has no text fields, so there's nothing to scroll
          // for anyway.
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 20, 0),
                  child: Consumer<LanguageController>(
                    builder: (context, lang, _) => GestureDetector(
                      onTap: () => lang.toggle(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(lang.isHindi ? 'हिं / EN' : 'EN / हिं',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C4DBF), Color(0xFFC1447F)],
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: const Center(child: Text('RB', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'serif'))),
              ),
              const SizedBox(height: 14),
              const Text.rich(TextSpan(children: [
                TextSpan(text: 'Rishta', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'serif', letterSpacing: 0.3)),
                TextSpan(text: 'Book', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Color(0xFFFFD877), fontFamily: 'serif', letterSpacing: 0.3)),
              ])),
              const SizedBox(height: 4),
              Text(context.t('authLanding.welcome'), style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const Spacer(flex: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                        ),
                        icon: const Icon(Icons.g_mobiledata, color: AppColors.saffron, size: 28),
                        label: Text(context.t('authLanding.continueGoogle')),
                        onPressed: _loading ? null : _signInWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.phone_android, color: Colors.white),
                        label: Text(context.t('authLanding.continueMobile')),
                        onPressed: _loading
                            ? null
                            : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneAuthScreen())),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailAuthScreen())),
                        child: Text(context.t('authLanding.signInEmail'),
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t('authLanding.terms'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10.5, color: Colors.white60, height: 1.5),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(context.t('authLanding.credit'),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white60)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
