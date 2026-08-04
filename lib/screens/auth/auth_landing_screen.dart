import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../widgets/scallop_header.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/credit_service.dart';
import '../../i18n/language_controller.dart';
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
          'credits': CreditService.signupBonus,
          'createdAt': DateTime.now(),
        });
        await _creditService.grantSignupBonus(uid);
      }
      // AuthGate reacts to the auth state + profile doc changing on its
      // own - no explicit navigation needed here.
    } catch (e) {
      _showSnack("Google साइन-इन में समस्या आई। / Google sign-in failed.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VideoScallopHeader(
              height: 300,
              videoAsset: 'assets/video/signin_bg.mp4',
              child: Stack(
                children: [
                  Positioned(
                    top: 4,
                    right: 4,
                    child: SafeArea(
                      bottom: false,
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
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 42),
                        ),
                        const SizedBox(height: 14),
                        const Text("RishtaBook", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'serif')),
                        const SizedBox(height: 4),
                        const Text("स्वागत है / Welcome", style: TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, color: AppColors.saffron, size: 28),
                      label: const Text("Google से जारी रखें / Continue with Google"),
                      onPressed: _loading ? null : _signInWithGoogle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.phone_android, color: Colors.white),
                      label: const Text("मोबाइल नंबर से जारी रखें / Continue with Mobile"),
                      onPressed: _loading
                          ? null
                          : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneAuthScreen())),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailAuthScreen())),
                      child: const Text("ईमेल से साइन-इन करें / Sign in with email instead",
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "जारी रखकर आप हमारी नियम व शर्तें स्वीकार करते हैं।\nBy continuing you agree to our Terms & Privacy Policy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, color: AppColors.ghost, height: 1.5),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Text("निर्माता / Created by Vijay Vishvakarma",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
