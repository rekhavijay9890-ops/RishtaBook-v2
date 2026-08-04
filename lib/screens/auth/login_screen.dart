import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../widgets/scallop_header.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/credit_service.dart';
import '../../services/kundali_service.dart';
import '../../i18n/language_controller.dart';
import '../root_shell.dart';

const List<String> kIndianStates = [
  'आंध्र प्रदेश','अरुणाचल प्रदेश','असम','बिहार','छत्तीसगढ़',
  'गोवा','गुजरात','हरियाणा','हिमाचल प्रदेश','झारखंड','कर्नाटक',
  'केरल','मध्य प्रदेश','महाराष्ट्र','मणिपुर','मेघालय','मिज़ोरम',
  'नागालैंड','ओडिशा','पंजाब','राजस्थान','सिक्किम','तमिलनाडु',
  'तेलंगाना','त्रिपुरा','उत्तर प्रदेश','उत्तराखंड','पश्चिम बंगाल',
  'अंडमान व निकोबार','चंडीगढ़','दादरा व नगर हवेली','दमन व दीव',
  'दिल्ली','जम्मू और कश्मीर','लद्दाख','लक्षद्वीप','पुदुच्चेरी',
];

class LoginScreen extends StatefulWidget {
  /// When non-null, this screen is shown to an ALREADY authenticated user
  /// whose profile is missing required fields (e.g. a first Google
  /// sign-in, which only sets fullName/email) — it renders the full
  /// registration form pre-filled, with no email/password fields, and
  /// submits via `updateUserProfile` instead of creating a new account.
  final User? completingProfileFor;

  const LoginScreen({super.key, this.completingProfileFor});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final CreditService _creditService = CreditService();

  bool get _completingProfile => widget.completingProfileFor != null;

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _isDisclaimerAccepted = false;
  bool _disclaimerError = false;
  bool _obscurePassword = true;

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();
  final _ageController      = TextEditingController();
  final _mobileController   = TextEditingController();
  final _genderController   = TextEditingController();
  final _villageController  = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController    = TextEditingController();
  final _religionController  = TextEditingController();
  final _categoryController  = TextEditingController();
  final _casteController     = TextEditingController();
  final _gotraController     = TextEditingController();
  final _occupationController = TextEditingController();
  final _brothersController  = TextEditingController();
  final _sistersController   = TextEditingController();
  final _familyDetailsController = TextEditingController();
  final _requirementsController  = TextEditingController();
  final _referralCodeController  = TextEditingController();

  String _rashi = '';
  String _nakshatra = '';
  String _manglik = 'no';

  @override
  void initState() {
    super.initState();
    if (_completingProfile) {
      _isLoginMode = false;
      _nameController.text = widget.completingProfileFor!.displayName ?? '';
      _emailController.text = widget.completingProfileFor!.email ?? '';
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  String? _required(String? value, String fieldName) =>
      (value == null || value.trim().isEmpty) ? "$fieldName भरना अनिवार्य है" : null;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return "ईमेल / Email भरना अनिवार्य है";
    if (!RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      return "सही ईमेल डालें / Enter valid email (e.g. name@gmail.com)";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "पासवर्ड / Password भरना अनिवार्य है";
    if (value.length < 6) return "पासवर्ड कम से कम 6 अक्षर / min 6 characters का होना चाहिए";
    return null;
  }

  String? _validateMobile(String? value) {
    final mobile = value?.trim() ?? '';
    if (mobile.isEmpty) return "मोबाइल नंबर / Mobile No. भरना अनिवार्य है";
    if (mobile.length < 10) return "मोबाइल नंबर / Mobile No. 10 अंक / digits का होना चाहिए";
    if (!RegExp(r'^[0-9]+$').hasMatch(mobile)) return "केवल अंक / Numbers only लिखें";
    return null;
  }

  Map<String, dynamic> _profileData() => {
        'fullName':      _nameController.text.trim(),
        'age':           _ageController.text.trim(),
        'mobile':        _mobileController.text.trim(),
        'gender':        _genderController.text.trim(),
        'religion':      _religionController.text.trim(),
        'category':      _categoryController.text.trim(),
        'caste':         _casteController.text.trim(),
        'gotra':         _gotraController.text.trim(),
        'village':       _villageController.text.trim(),
        'district':      _districtController.text.trim(),
        'state':         _stateController.text.trim(),
        'occupation':    _occupationController.text.trim(),
        'brothers':      _brothersController.text.trim(),
        'sisters':       _sistersController.text.trim(),
        'familyDetails': _familyDetailsController.text.trim(),
        'requirements':  _requirementsController.text.trim(),
        'rashi':         _rashi,
        'nakshatra':     _nakshatra,
        'manglik':       _manglik,
      };

  Future<void> _submitForm() async {
    setState(() => _disclaimerError = false);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!_isLoginMode && !_completingProfile && !_isDisclaimerAccepted) {
      setState(() => _disclaimerError = true);
    }
    if (!formValid || (!_isLoginMode && !_completingProfile && !_isDisclaimerAccepted)) {
      _showSnack("कृपया फ़ॉर्म में दी गई त्रुटियाँ सुधारें।");
      return;
    }

    setState(() => _isLoading = true);

    if (_completingProfile) {
      try {
        await _profileService.updateUserProfile(widget.completingProfileFor!.uid, {
          ..._profileData(),
          'email': widget.completingProfileFor!.email ?? '',
        });
      } catch (_) {
        _showSnack("कुछ गलत हो गया। दोबारा कोशिश करें।");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLoginMode) {
        await _authService.signIn(email, password);
      } else {
        final userCredential = await _authService.register(email, password);
        final uid = userCredential.user!.uid;
        await _profileService.createUserProfile(uid, {
          'uid': uid,
          ..._profileData(),
          'email': email,
          'verificationStatus': 'none',
          'isVerified': false,
          'credits': CreditService.signupBonus,
          'createdAt': DateTime.now(),
        });
        await _creditService.grantSignupBonus(uid);
        final referralCode = _referralCodeController.text.trim();
        if (referralCode.isNotEmpty && referralCode != uid) {
          try {
            await _creditService.grantReferralBonus(referralCode, friendName: _nameController.text.trim());
            // Best-effort: if the referrer logged this phone number via
            // "Invite & Earn" → add by mobile, flip that invite from
            // pending to completed. No-ops silently if they shared a
            // link/code instead, or the numbers don't match.
            await _creditService.tryCompleteManualInvite(referralCode, phone: _mobileController.text.trim());
          } catch (_) {
            // Invalid/unknown referral code — signup still succeeds.
          }
        }
      }
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RootShell()), (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      String friendly = "खाता बनाने में समस्या आई।";
      if (e.code == 'email-already-in-use') {
        friendly = "यह ईमेल पहले से पंजीकृत है। लॉगिन करें।";
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        friendly = "ईमेल या पासवर्ड गलत है।";
      } else if (e.code == 'weak-password') {
        friendly = "पासवर्ड बहुत कमज़ोर है, कम से कम 6 अक्षर रखें।";
      } else if (e.code == 'network-request-failed') {
        friendly = "इंटरनेट कनेक्शन जाँचें।";
      }
      _showSnack(friendly);
    } catch (e) {
      _showSnack("कुछ गलत हो गया। दोबारा कोशिश करें।");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final uid = userCredential.user!.uid;
        await _profileService.createUserProfile(uid, {
          'uid':      uid,
          'fullName': userCredential.user!.displayName ?? 'नया उपयोगकर्ता',
          'email':    userCredential.user!.email,
          'verificationStatus': 'none',
          'isVerified': false,
          'credits': CreditService.signupBonus,
          'createdAt': DateTime.now(),
        });
        await _creditService.grantSignupBonus(uid);
      }
      // AuthGate reacts to the auth-state change on its own — if the
      // profile is still incomplete it will route back here in
      // completingProfileFor mode instead of leaving the user stuck.
    } catch (e) {
      _showSnack("Google लॉगिन में समस्या आई। दोबारा कोशिश करें।");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final ctrl = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("पासवर्ड रीसेट करें / Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("अपना ईमेल डालें / Enter your email, हम रीसेट लिंक भेजेंगे / we'll send a reset link."),
            const SizedBox(height: 12),
            TextField(controller: ctrl, decoration: const InputDecoration(hintText: "ईमेल / Email ID")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("रद्द करें / Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                try {
                  await _authService.sendPasswordResetEmail(ctrl.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnack("पासवर्ड रीसेट लिंक भेज दिया गया है!", isError: false);
                  }
                } catch (_) {
                  if (context.mounted) _showSnack("त्रुटि: ईमेल नहीं मिला या गलत है।");
                }
              }
            },
            child: const Text("लिंक भेजें / Send Link"),
          ),
        ],
      ),
    );
  }

  Widget _field(IconData icon, String hint, TextEditingController controller,
      {bool isPassword = false, int maxLines = 1, bool isNumber = false,
       String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      maxLines: isPassword ? 1 : maxLines,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.saffron, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.ghost),
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
        prefixIcon: Icon(icon, color: AppColors.saffron, size: 20),
        hintText: hint,
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.saffron, fontSize: 14.5)),
      );

  Widget _dobField() {
    return TextFormField(
      controller: _ageController,
      readOnly: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) => _required(v, "जन्म तिथि"),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000, 1, 1),
          firstDate: DateTime(1950),
          lastDate: DateTime.now().subtract(const Duration(days: 6570)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.saffron, onPrimary: Colors.white, onSurface: AppColors.ink),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() {
            _ageController.text =
                "${picked.day.toString().padLeft(2,'0')}/${picked.month.toString().padLeft(2,'0')}/${picked.year}";
          });
        }
      },
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.saffron, size: 20),
        hintText: "जन्म तिथि / Date of Birth (DD/MM/YYYY)",
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _emailController, _passwordController, _nameController, _ageController,
      _mobileController, _genderController, _villageController, _districtController,
      _stateController, _religionController, _categoryController, _casteController,
      _gotraController, _occupationController, _brothersController, _sistersController,
      _familyDetailsController, _requirementsController, _referralCodeController,
    ]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showFullForm = !_isLoginMode || _completingProfile;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VideoScallopHeader(
                height: 260,
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
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.favorite, color: Colors.white, size: 42),
                          ),
                          const SizedBox(height: 14),
                          const Text("RishtaBook",
                              style: TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w700,
                                  color: Colors.white, fontFamily: 'serif')),
                          const SizedBox(height: 4),
                          Text(
                              _completingProfile
                                  ? "अपनी प्रोफ़ाइल पूरी करें / Complete your profile"
                                  : (_isLoginMode ? "स्वागत है / Welcome Back" : "नया खाता बनाएँ / Create Account"),
                              style: const TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showFullForm) ...[
                      _sectionHeader("👤 व्यक्तिगत जानकारी / Personal Info"),
                      _field(Icons.person_outline, "पूरा नाम / Full Name",
                          _nameController, validator: (v) => _required(v, "पूरा नाम / Full Name")),
                      const SizedBox(height: 12),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _dobField()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dropdown(
                            Icons.people_outline, "लिंग / Gender",
                            const ["पुरुष / Male", "स्त्री / Female", "अन्य / Other"],
                            "लिंग / Gender", (v) => setState(() => _genderController.text = v ?? '')),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _field(Icons.phone_outlined, "मोबाइल नंबर / Mobile No. (Admin only)",
                          _mobileController, isNumber: true, validator: _validateMobile),

                      _sectionHeader("🛕 धर्म एवं समाज / Religion & Community"),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: _dropdown(
                            Icons.menu_book_outlined, "धर्म / Religion",
                            const ["हिन्दू / Hindu", "मुस्लिम / Muslim", "सिख / Sikh", "ईसाई / Christian", "बौद्ध / Buddhist", "जैन / Jain", "अन्य / Other"],
                            "धर्म / Religion", (v) => setState(() => _religionController.text = v ?? '')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dropdown(
                            Icons.groups_outlined, "वर्ग / Category",
                            const ["सामान्य / General", "OBC", "SC", "ST", "अन्य / Other"],
                            "वर्ग / Category", (v) => setState(() => _categoryController.text = v ?? '')),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _field(Icons.account_tree_outlined, "जाति / Caste", _casteController)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(Icons.spa_outlined, "गोत्र / Gotra", _gotraController)),
                      ]),

                      _sectionHeader("📍 पता / Address"),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: _field(Icons.home_outlined, "गाँव / Village or Town",
                              _villageController, validator: (v) => _required(v, "गाँव/शहर")),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(Icons.location_city_outlined, "जिला / District",
                              _districtController, validator: (v) => _required(v, "जिला / District")),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (v) => _required(v, "राज्य / State"),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.map_outlined, color: AppColors.saffron, size: 20),
                          hintText: "राज्य / State",
                        ),
                        items: kIndianStates
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _stateController.text = v ?? ''),
                      ),

                      _sectionHeader("💼 व्यवसाय / Occupation"),
                      _dropdown(
                        Icons.work_outline, "व्यवसाय / Occupation",
                        const ["नौकरी / Job", "व्यापार / Business", "खेती / Farming", "स्वरोजगार / Self Employed", "विद्यार्थी / Student", "अन्य / Other"],
                        "व्यवसाय / Occupation", (v) => setState(() => _occupationController.text = v ?? '')),

                      _sectionHeader("👨‍👩‍👧‍👦 पारिवारिक जानकारी / Family Details"),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: TextFormField(
                            controller: _brothersController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.saffron, size: 20),
                              hintText: "भाइयों की संख्या / No. of Brothers",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _sistersController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.saffron, size: 20),
                              hintText: "बहनों की संख्या / No. of Sisters",
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _field(Icons.family_restroom_outlined,
                          "पारिवारिक विवरण / Family Details (Father/Mother occupation, income, etc.)",
                          _familyDetailsController, maxLines: 2,
                          validator: (v) => _required(v, "पारिवारिक विवरण")),

                      _sectionHeader("💑 जीवनसाथी की अपेक्षाएँ / Partner Preference"),
                      _field(Icons.list_alt_outlined,
                          "कोई विशेष शर्त / Any preference or condition",
                          _requirementsController, maxLines: 2,
                          validator: (v) => _required(v, "अपेक्षाएँ")),

                      _sectionHeader("⭐ कुंडली (वैकल्पिक) / Kundali (optional)"),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.brightness_7_outlined, color: AppColors.saffron, size: 20),
                              hintText: "राशि / Rashi",
                            ),
                            items: KundaliService.rashis.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _rashi = v ?? ''),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.star_border, color: AppColors.saffron, size: 20),
                              hintText: "नक्षत्र / Nakshatra",
                            ),
                            items: KundaliService.nakshatras.map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _nakshatra = v ?? ''),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _manglik,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.warning_amber_outlined, color: AppColors.saffron, size: 20),
                          hintText: "मांगलिक / Manglik",
                        ),
                        items: const [
                          DropdownMenuItem(value: 'no', child: Text('नहीं / No')),
                          DropdownMenuItem(value: 'yes', child: Text('हाँ / Yes')),
                        ],
                        onChanged: (v) => setState(() => _manglik = v ?? 'no'),
                      ),

                      if (!_completingProfile) ...[
                        _sectionHeader("🎁 रेफ़रल कोड / Referral code (optional)"),
                        _field(Icons.card_giftcard_outlined, "किसी दोस्त का रेफ़रल कोड / Friend's referral code", _referralCodeController),
                      ],
                    ],

                    if (!_completingProfile) ...[
                      const SizedBox(height: 16),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Checkbox(
                          value: _isDisclaimerAccepted,
                          onChanged: (v) => setState(() {
                            _isDisclaimerAccepted = v ?? false;
                            if (_isDisclaimerAccepted) _disclaimerError = false;
                          }),
                          activeColor: AppColors.saffron,
                        ),
                        const Expanded(
                          child: Text(
                            "अस्वीकरण: हमारा कार्य केवल दो परिवारों को जोड़ना है। "
                            "जाँच-पड़ताल की जिम्मेदारी आपकी है। "
                            "किसी भी धोखाधड़ी के लिए हम उत्तरदायी नहीं हैं।",
                            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                          ),
                        ),
                      ]),
                      if (_disclaimerError && !_isLoginMode)
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("अस्वीकरण / Disclaimer स्वीकार करना अनिवार्य है",
                                style: TextStyle(color: AppColors.error, fontSize: 12)),
                          ),
                        ),
                      const SizedBox(height: 18),
                    ],

                    if (!_completingProfile) ...[
                      _field(Icons.email_outlined, "ईमेल / Email ID", _emailController,
                          validator: _validateEmail),
                      const SizedBox(height: 14),
                      _field(Icons.lock_outline, "पासवर्ड / Password", _passwordController,
                          isPassword: true, validator: _validatePassword),
                      if (_isLoginMode)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text("पासवर्ड भूल गए? / Forgot Password?")),
                        ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.4))
                            : Text(_completingProfile
                                ? "प्रोफ़ाइल सहेजें / Save Profile"
                                : (_isLoginMode ? "सुरक्षित लॉगिन / Secure Login" : "पंजीकरण करें / Sign Up")),
                      ),
                    ),
                    if (!_completingProfile) ...[
                      const SizedBox(height: 20),
                      const Row(children: [
                        Expanded(child: Divider()),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("या / OR")),
                        Expanded(child: Divider()),
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.g_mobiledata, color: AppColors.saffron, size: 28),
                          label: const Text("Google से लॉगिन / Continue with Google"),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLoginMode ? "नया खाता नहीं है? / No account? " : "पहले से खाता है? / Already registered? ",
                            style: const TextStyle(color: AppColors.muted)),
                          GestureDetector(
                            onTap: () => setState(() {
                              _isLoginMode = !_isLoginMode;
                              _emailController.clear();
                              _passwordController.clear();
                            }),
                            child: Text(_isLoginMode ? "पंजीकरण करें / Sign Up" : "लॉगिन करें",
                                style: const TextStyle(
                                    color: AppColors.saffron, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: Text(
                  "निर्माता / Created by Vijay Vishvakarma",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
