import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';

/// Email/password sign-in only - kept for accounts created before Google
/// and Mobile became the standard entry points on [AuthLandingScreen].
/// There is no sign-up here on purpose; new accounts use Google or Mobile.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});
  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

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

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await _authService.signIn(_emailController.text.trim(), _passwordController.text.trim());
      // AuthGate reacts to the auth-state change on its own.
    } on FirebaseAuthException catch (e) {
      String friendly = "साइन-इन में समस्या आई। / Sign-in failed.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        friendly = "ईमेल या पासवर्ड गलत है। / Wrong email or password.";
      } else if (e.code == 'network-request-failed') {
        friendly = "इंटरनेट कनेक्शन जाँचें। / Check your internet connection.";
      }
      _showSnack(friendly);
    } catch (_) {
      _showSnack("कुछ गलत हो गया। / Something went wrong.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final ctrl = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("पासवर्ड रीसेट करें / Reset Password"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "ईमेल / Email ID")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("रद्द करें / Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              try {
                await _authService.sendPasswordResetEmail(ctrl.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("पासवर्ड रीसेट लिंक भेज दिया गया है!"), backgroundColor: AppColors.success));
                }
              } catch (_) {
                if (context.mounted) _showSnack("त्रुटि: ईमेल नहीं मिला या गलत है।");
              }
            },
            child: const Text("लिंक भेजें / Send Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ईमेल से साइन-इन / Sign in with Email"),
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
                decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, color: AppColors.saffron), hintText: "ईमेल / Email ID"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "ईमेल भरना अनिवार्य है" : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.saffron),
                  hintText: "पासवर्ड / Password",
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.ghost),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? "पासवर्ड भरना अनिवार्य है" : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _showForgotPasswordDialog, child: const Text("पासवर्ड भूल गए? / Forgot Password?")),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("साइन-इन करें / Sign In"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
