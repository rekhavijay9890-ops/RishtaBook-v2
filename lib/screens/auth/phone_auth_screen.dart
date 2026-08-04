import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/credit_service.dart';

/// Firebase Phone Auth: enter number -> receive SMS OTP -> verify.
/// Requires the Phone provider enabled in Firebase Console.
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _creditService = CreditService();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  String? _verificationId;
  String _phoneDigits = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: error ? AppColors.error : AppColors.success));
  }

  Future<void> _completeSignIn(UserCredential credential) async {
    if (credential.additionalUserInfo?.isNewUser ?? false) {
      final uid = credential.user!.uid;
      await _profileService.createUserProfile(uid, {
        'uid': uid,
        'fullName': '',
        'mobile': _phoneDigits,
        'email': '',
        'verificationStatus': 'none',
        'isVerified': false,
        'credits': CreditService.signupBonus,
        'createdAt': DateTime.now(),
      });
      await _creditService.grantSignupBonus(uid);
    }
    // AuthGate reacts to the auth-state change on its own.
  }

  Future<void> _sendOtp() async {
    final digits = _phoneController.text.trim();
    if (digits.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(digits)) {
      _showSnack("सही 10 अंकों का मोबाइल नंबर डालें / Enter a valid 10-digit number");
      return;
    }
    setState(() => _loading = true);
    _phoneDigits = digits;
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: '+91$digits',
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _loading = false;
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _loading = false);
          _showSnack(e.message ?? "OTP भेजने में समस्या आई। / Could not send OTP.");
        },
        onAutoVerified: (credential) async {
          await _completeSignIn(credential);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      _showSnack("OTP भेजने में समस्या आई। / Could not send OTP.");
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6 || _verificationId == null) {
      _showSnack("सही OTP डालें / Enter the 6-digit OTP");
      return;
    }
    setState(() => _loading = true);
    try {
      final credential = await _authService.signInWithSmsCode(_verificationId!, code);
      await _completeSignIn(credential);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.code == 'invalid-verification-code'
          ? "गलत OTP। दोबारा कोशिश करें। / Wrong OTP, try again."
          : (e.message ?? "सत्यापन विफल। / Verification failed."));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_otpSent ? "OTP दर्ज करें / Enter OTP" : "मोबाइल नंबर / Mobile Number"),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.pageBg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            if (!_otpSent) ...[
              const Text("हम आपको एक OTP भेजेंगे / We'll send you a one-time code",
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text("+91", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(hintText: "98XXXXXX21", counterText: ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("OTP भेजें / Send OTP"),
                ),
              ),
            ] else ...[
              Text("$_phoneDigits पर भेजा गया OTP डालें / Enter the OTP sent to +91 $_phoneDigits",
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("सत्यापित करें / Verify"),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => setState(() => _otpSent = false),
                  child: const Text("नंबर बदलें / Change number", style: TextStyle(color: AppColors.muted)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
