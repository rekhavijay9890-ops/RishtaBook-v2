import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/credit_service.dart';
import '../../i18n/strings.dart';

/// Email/password sign-in, with a "Create Account" mode for genuinely new
/// signups by email (the third entry point alongside Google and Mobile).
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});
  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _creditService = CreditService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _signUpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
  }

  /// Pops this screen back to the root route once sign-in/sign-up
  /// succeeds. EmailAuthScreen is reached via Navigator.push on top of
  /// AuthLandingScreen (itself the content AuthGate swaps in place), so
  /// AuthGate reacting to the auth-state change and rebuilding its OWN
  /// content isn't enough by itself - this screen would just keep sitting
  /// on top of the stack, covering that updated content, unless it pops.
  void _returnToAuthGate() {
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await _authService.signIn(_emailController.text.trim(), _passwordController.text.trim());
      _returnToAuthGate();
    } on FirebaseAuthException catch (e) {
      String friendly = context.t('emailAuth.signInFailed');
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        friendly = context.t('emailAuth.wrongCreds');
      } else if (e.code == 'network-request-failed') {
        friendly = context.t('emailAuth.networkError');
      } else if (e.code == 'operation-not-allowed') {
        friendly = context.t('emailAuth.providerDisabled');
      }
      _showSnack(friendly);
    } catch (_) {
      _showSnack(context.t('common.error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final credential = await _authService.register(_emailController.text.trim(), _passwordController.text.trim());
      final uid = credential.user!.uid;
      await _profileService.createUserProfile(uid, {
        'uid': uid,
        'fullName': '',
        'email': _emailController.text.trim(),
        'verificationStatus': 'none',
        'isVerified': false,
        'credits': CreditService.signupBonus,
        'createdAt': DateTime.now(),
        'referralCode': CreditService.generateReferralCode(),
      });
      await _creditService.grantSignupBonus(uid);
      _returnToAuthGate();
    } on FirebaseAuthException catch (e) {
      String friendly = context.t('emailAuth.signUpFailed');
      if (e.code == 'email-already-in-use') {
        friendly = context.t('emailAuth.emailInUse');
      } else if (e.code == 'weak-password') {
        friendly = context.t('emailAuth.weakPassword');
      } else if (e.code == 'invalid-email') {
        friendly = context.t('emailAuth.invalidEmail');
      } else if (e.code == 'network-request-failed') {
        friendly = context.t('emailAuth.networkError');
      } else if (e.code == 'operation-not-allowed') {
        // The Email/Password provider isn't enabled in Firebase Console ->
        // Authentication -> Sign-in method. Every signup attempt fails
        // with this exact code until that's turned on.
        friendly = context.t('emailAuth.providerDisabled');
      }
      _showSnack(friendly);
    } catch (_) {
      _showSnack(context.t('common.error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final ctrl = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('emailAuth.resetTitle')),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: context.t('emailAuth.emailHint'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              try {
                await _authService.sendPasswordResetEmail(ctrl.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.t('emailAuth.resetSent')), backgroundColor: AppColors.success));
                }
              } catch (_) {
                if (context.mounted) _showSnack(context.t('emailAuth.resetError'));
              }
            },
            child: Text(context.t('emailAuth.sendLink')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_signUpMode ? context.t('emailAuth.createAccount') : context.t('emailAuth.title')),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.pageBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.email_outlined, color: AppColors.saffron), hintText: context.t('emailAuth.emailHint')),
                validator: (v) => (v == null || v.trim().isEmpty) ? context.t('emailAuth.emailRequired') : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.saffron),
                  hintText: context.t('emailAuth.passwordHint'),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.ghost),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? context.t('emailAuth.passwordRequired') : null,
              ),
              if (!_signUpMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _showForgotPasswordDialog, child: Text(context.t('emailAuth.forgotPassword'))),
                ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_signUpMode ? _signUp : _signIn),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_signUpMode ? context.t('emailAuth.signUpButton') : context.t('emailAuth.signInButton')),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => setState(() => _signUpMode = !_signUpMode),
                  child: Text(_signUpMode ? context.t('emailAuth.haveAccount') : context.t('emailAuth.noAccount'),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
