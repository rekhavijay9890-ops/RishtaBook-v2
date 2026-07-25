import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../dashboard/dashboard_screen.dart';

const Color kBrandColor = Color(0xFF0F766E);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _isDisclaimerAccepted = false;

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
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final isEmailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);

    if (email.isEmpty || password.isEmpty) {
      _showSnack("Kripya Email aur Password bharein.");
      setState(() => _isLoading = false);
      return;
    }
    if (!isEmailValid) {
      _showSnack("Kripya ek sahi Gmail ID daalein.");
      setState(() => _isLoading = false);
      return;
    }

    if (!_isLoginMode) {
      if (_nameController.text.trim().isEmpty ||
          _ageController.text.trim().isEmpty ||
          _mobileController.text.trim().isEmpty ||
          _genderController.text.trim().isEmpty ||
          _religionController.text.trim().isEmpty ||
          _categoryController.text.trim().isEmpty ||
          _villageController.text.trim().isEmpty ||
          _districtController.text.trim().isEmpty ||
          _stateController.text.trim().isEmpty ||
          _occupationController.text.trim().isEmpty ||
          _familyDetailsController.text.trim().isEmpty ||
          _requirementsController.text.trim().isEmpty) {
        _showSnack("Kripya sabhi details bharein, koi bhi field khali na chhodein.");
        setState(() => _isLoading = false);
        return;
      }
      if (_mobileController.text.trim().length < 10) {
        _showSnack("Kripya ek sahi 10-digit Mobile Number daalein.");
        setState(() => _isLoading = false);
        return;
      }
      if (!_isDisclaimerAccepted) {
        _showSnack("Kripya Disclaimer par tick karke agree karein.");
        setState(() => _isLoading = false);
        return;
      }
    }

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
      _showSnack(e.message ?? "Error: Account banane mein dikkat aayi.");
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
      _showSnack("Error: ${e.toString()}");
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
      {bool isPassword = false, int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      maxLines: isPassword ? 1 : maxLines,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kBrandColor),
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dropdown(IconData icon, String hint, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kBrandColor),
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _dobField() {
    return TextField(
      controller: _ageController,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000, 1, 1),
          firstDate: DateTime(1950),
          lastDate: DateTime.now().subtract(const Duration(days: 6570)),
        );
        if (picked != null) {
          setState(() {
            _ageController.text =
                "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
          });
        }
      },
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.calendar_today, color: kBrandColor),
        hintText: "Date of Birth",
        border: OutlineInputBorder(),
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: kBrandColor, size: 56),
              const SizedBox(height: 16),
              Text(_isLoginMode ? "Welcome Back!" : "Create Account",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandColor)),
              const SizedBox(height: 28),
              if (!_isLoginMode) ...[
                _field(Icons.person, "Full Name", _nameController),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dobField()),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _dropdown(Icons.people, "Gender", const ["Male", "Female", "Other"],
                          (v) => _genderController.text = v ?? '')),
                ]),
                const SizedBox(height: 12),
                _field(Icons.phone, "Mobile Number (For Admin Only)", _mobileController,
                    isNumber: true),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _dropdown(Icons.menu_book, "Religion",
                          const ["Hindu", "Muslim", "Sikh", "Ishai"],
                          (v) => _religionController.text = v ?? '')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _dropdown(Icons.groups, "Category",
                          const ["General", "OBC", "SC", "ST", "Other"],
                          (v) => _categoryController.text = v ?? '')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(Icons.home, "Gaon / Town / City", _villageController)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(Icons.location_city, "Jila (District)", _districtController)),
                ]),
                const SizedBox(height: 12),
                _field(Icons.map, "Pradesh (State)", _stateController),
                const SizedBox(height: 12),
                _dropdown(Icons.work, "Occupation", const ["Job", "Business", "Farming", "Other"],
                    (v) => _occupationController.text = v ?? ''),
                const SizedBox(height: 12),
                _field(Icons.family_restroom, "Family Details (Occupation, Income, etc.)",
                    _familyDetailsController, maxLines: 2),
                const SizedBox(height: 12),
                _field(Icons.list_alt, "Any other requirement / condition",
                    _requirementsController, maxLines: 2),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _isDisclaimerAccepted,
                      onChanged: (v) => setState(() => _isDisclaimerAccepted = v ?? false),
                      activeColor: kBrandColor,
                    ),
                    const Expanded(
                      child: Text(
                        "Disclaimer: Hamara kaam bas do families ko connect karana hai, Ladka/Ladki aur pariwar ke baare main janch aur padtal karna aapki jimmedaari hai. Hamari app ke through koi bhi galat ya fraud activity ke liye ham zimmedar nahi hain.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              _field(Icons.email, "Gmail ID", _emailController),
              const SizedBox(height: 12),
              _field(Icons.lock, "Password", _passwordController, isPassword: true),
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
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kBrandColor),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLoginMode ? "Secure Login" : "Sign Up",
                          style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR")),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.account_circle, color: Colors.red),
                  label: const Text("Continue with Google"),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLoginMode ? "Don't have an account? " : "Already have an account? "),
                  GestureDetector(
                    onTap: () => setState(() {
                      _isLoginMode = !_isLoginMode;
                      _emailController.clear();
                      _passwordController.clear();
                    }),
                    child: Text(_isLoginMode ? "Sign Up" : "Login",
                        style: const TextStyle(color: kBrandColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
