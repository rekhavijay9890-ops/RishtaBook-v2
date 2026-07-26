import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/scallop_header.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _isDisclaimerAccepted = false;
  bool _disclaimerError = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _mobileController = TextEditingController();
  final _genderController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _religionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _occupationController = TextEditingController();
  final _familyDetailsController = TextEditingController();
  final _requirementsController = TextEditingController();

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  String? _required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName zaroori hai";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return "Email zaroori hai";
    final isValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    if (!isValid) return "Sahi email format daalein (jaise name@gmail.com)";
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return "Password zaroori hai";
    if (password.length < 6) return "Password kam se kam 6 characters ka ho";
    return null;
  }

  String? _validateMobile(String? value) {
    final mobile = value?.trim() ?? '';
    if (mobile.isEmpty) return "Mobile number zaroori hai";
    if (mobile.length < 10) return "Mobile number 10 digit ka hona chahiye";
    if (!RegExp(r'^[0-9]+$').hasMatch(mobile)) return "Sirf numbers likhein";
    return null;
  }

  Future<void> _submitForm() async {
    setState(() => _disclaimerError = false);

    final formValid = _formKey.currentState?.validate() ?? false;

    if (!_isLoginMode && !_isDisclaimerAccepted) {
      setState(() => _disclaimerError = true);
    }

    if (!formValid || (!_isLoginMode && !_isDisclaimerAccepted)) {
      _showSnack("Kripya form mein highlighted errors theek karein.");
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLoginMode) {
        await _authService.signIn(email, password);
      } else {
        final userCredential = await _authService.register(email, password);
        final selectedGender = _genderController.text.trim();

        await _profileService.createUserProfile(userCredential.user!.uid, {
          'uid': userCredential.user!.uid,
          'fullName': _nameController.text.trim(),
          'age': _ageController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'gender': selectedGender,
          'religion': _religionController.text.trim(),
          'category': _categoryController.text.trim(),
          'village': _villageController.text.trim(),
          'district': _districtController.text.trim(),
          'state': _stateController.text.trim(),
          'occupation': _occupationController.text.trim(),
          'familyDetails': _familyDetailsController.text.trim(),
          'requirements': _requirementsController.text.trim(),
          'email': email,
          'verificationStatus': 'none',
          'isVerified': false,
          'createdAt': DateTime.now(),
        });
      }
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String friendly = e.message ?? "Account banane mein dikkat aayi.";
      if (e.code == 'email-already-in-use') {
        friendly = "Ye email pehle se registered hai. Login try karein.";
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        friendly = "Email ya Password galat hai.";
      } else if (e.code == 'weak-password') {
        friendly = "Password bahut kamzor hai, kam se kam 6 characters rakhein.";
      } else if (e.code == 'network-request-failed') {
        friendly = "Internet connection check karein.";
      }
      _showSnack(friendly);
    } catch (e) {
      _showSnack("Kuch galat ho gaya. Dobara try karein.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _profileService.createUserProfile(userCredential.user!.uid, {
          'uid': userCredential.user!.uid,
          'fullName': userCredential.user!.displayName ?? 'Naya User',
          'email': userCredential.user!.email,
          'verificationStatus': 'none',
          'isVerified': false,
          'createdAt': DateTime.now(),
        });
      }
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      }
    } catch (e) {
      _showSnack("Google Sign-In mein error aayi. Dobara try karein.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Apna registered email daalein, hum aapko password reset karne ka link bhejenge."),
            const SizedBox(height: 12),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(hintText: "Gmail ID"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isNotEmpty) {
                try {
                  await _authService.sendPasswordResetEmail(resetEmailController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnack("Password reset link aapke email par bhej diya gaya hai!",
                        isError: false);
                  }
                } catch (e) {
                  if (context.mounted) _showSnack("Error: Email nahi mila ya galat hai.");
                }
              }
            },
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
  }

  Widget _field(IconData icon, String hint, TextEditingController controller,
      {bool isPassword = false,
      int maxLines = 1,
      bool isNumber = false,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      maxLines: isPassword ? 1 : maxLines,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.muted),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        hintText: hint,
      ),
    );
  }

  Widget _dropdown(IconData icon, String hint, List<String> items, String fieldName,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) => _required(v, fieldName),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        hintText: hint,
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _dobField() {
    return TextFormField(
      controller: _ageController,
      readOnly: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) => _required(v, "Date of Birth"),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000, 1, 1),
          firstDate: DateTime(1950),
          lastDate: DateTime.now().subtract(const Duration(days: 6570)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.ink,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _ageController.text =
                "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
          });
        }
      },
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
        hintText: "Date of Birth",
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _mobileController.dispose();
    _genderController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _religionController.dispose();
    _categoryController.dispose();
    _occupationController.dispose();
    _familyDetailsController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScallopHeader(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: 14),
                      Text("RishtaBook",
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(_isLoginMode ? "Welcome back" : "Create your account",
                          style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isLoginMode) ...[
                      _field(Icons.person_outline, "Full Name", _nameController,
                          validator: (v) => _required(v, "Full Name")),
                      const SizedBox(height: 14),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _dobField()),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _dropdown(Icons.people_outline, "Gender",
                                const ["Male", "Female", "Other"], "Gender",
                                (v) => setState(() => _genderController.text = v ?? ''))),
                      ]),
                      const SizedBox(height: 14),
                      _field(Icons.phone_outlined, "Mobile Number (For Admin Only)",
                          _mobileController, isNumber: true, validator: _validateMobile),
                      const SizedBox(height: 14),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                            child: _dropdown(Icons.menu_book_outlined, "Religion",
                                const ["Hindu", "Muslim", "Sikh", "Ishai"], "Religion",
                                (v) => setState(() => _religionController.text = v ?? ''))),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _dropdown(Icons.groups_outlined, "Category",
                                const ["General", "OBC", "SC", "ST", "Other"], "Category",
                                (v) => setState(() => _categoryController.text = v ?? ''))),
                      ]),
                      const SizedBox(height: 14),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                            child: _field(Icons.home_outlined, "Gaon / Town / City",
                                _villageController, validator: (v) => _required(v, "City"))),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _field(Icons.location_city_outlined, "Jila (District)",
                                _districtController, validator: (v) => _required(v, "District"))),
                      ]),
                      const SizedBox(height: 14),
                      _field(Icons.map_outlined, "Pradesh (State)", _stateController,
                          validator: (v) => _required(v, "State")),
                      const SizedBox(height: 14),
                      _dropdown(Icons.work_outline, "Occupation",
                          const ["Job", "Business", "Farming", "Other"], "Occupation",
                          (v) => setState(() => _occupationController.text = v ?? '')),
                      const SizedBox(height: 14),
                      _field(Icons.family_restroom_outlined,
                          "Family Details (Occupation, Income, etc.)", _familyDetailsController,
                          maxLines: 2, validator: (v) => _required(v, "Family Details")),
                      const SizedBox(height: 14),
                      _field(Icons.list_alt_outlined, "Any other requirement / condition",
                          _requirementsController,
                          maxLines: 2, validator: (v) => _required(v, "Requirement")),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _isDisclaimerAccepted,
                            onChanged: (v) => setState(() {
                              _isDisclaimerAccepted = v ?? false;
                              if (_isDisclaimerAccepted) _disclaimerError = false;
                            }),
                            activeColor: AppColors.primary,
                          ),
                          const Expanded(
                            child: Text(
                              "Disclaimer: Hamara kaam bas do families ko connect karana hai, Ladka/Ladki aur pariwar ke baare main janch aur padtal karna aapki jimmedaari hai. Hamari app ke through koi bhi galat ya fraud activity ke liye ham zimmedar nahi hain.",
                              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                      if (_disclaimerError)
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Disclaimer accept karna zaroori hai",
                                style: TextStyle(color: AppColors.error, fontSize: 12)),
                          ),
                        ),
                      const SizedBox(height: 18),
                    ],
                    _field(Icons.email_outlined, "Gmail ID", _emailController,
                        validator: _validateEmail),
                    const SizedBox(height: 14),
                    _field(Icons.lock_outline, "Password", _passwordController,
                        isPassword: true, validator: _validatePassword),
                    if (_isLoginMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text("Forgot Password?")),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.4),
                              )
                            : Text(_isLoginMode ? "Secure Login" : "Sign Up"),
                      ),
                    ),
                    const OrnateDivider(verticalPadding: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.g_mobiledata, color: AppColors.primary, size: 28),
                        label: const Text("Continue with Google"),
                        onPressed: _isLoading ? null : _signInWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            _isLoginMode
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: const TextStyle(color: AppColors.muted)),
                        GestureDetector(
                          onTap: () => setState(() {
                            _isLoginMode = !_isLoginMode;
                            _emailController.clear();
                            _passwordController.clear();
                          }),
                          child: Text(_isLoginMode ? "Sign Up" : "Login",
                              style: const TextStyle(
                                  color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
