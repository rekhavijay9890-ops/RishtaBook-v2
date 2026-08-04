import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import '../../services/profile_service.dart';
import '../../services/credit_service.dart';

/// Short, mandatory step shown right after ANY successful sign-in
/// (Google, Mobile, or Email) whose profile is missing these fields —
/// closes the gap where Google sign-in used to skip straight past both
/// the basic-info step AND the disclaimer/consent that email signup
/// always required.
class BasicDetailsScreen extends StatefulWidget {
  final User user;
  /// The user's existing `users/{uid}` doc, if any — e.g. a pre-redesign
  /// account that already has fullName/gender/mobile filled in but never
  /// went through consent capture. Prefilled here instead of starting blank.
  final Map<String, dynamic>? existingData;
  const BasicDetailsScreen({super.key, required this.user, this.existingData});

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _creditService = CreditService();

  late final _nameController = TextEditingController(
      text: (widget.existingData?['fullName'] as String?)?.isNotEmpty == true
          ? widget.existingData!['fullName']
          : (widget.user.displayName ?? ''));
  late final _dobController = TextEditingController(text: widget.existingData?['age'] ?? '');
  final _mobileController = TextEditingController();
  final _referralController = TextEditingController();
  late String _gender = widget.existingData?['gender'] ?? '';
  bool _consent = false;
  bool _consentError = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.user.phoneNumber != null) {
      _mobileController.text = widget.user.phoneNumber!.replaceFirst('+91', '');
    } else if ((widget.existingData?['mobile'] as String?)?.isNotEmpty == true) {
      _mobileController.text = widget.existingData!['mobile'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _consentError = false);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!_consent) setState(() => _consentError = true);
    if (!formValid || _gender.isEmpty || !_consent) return;

    setState(() => _saving = true);
    try {
      await _profileService.updateUserProfile(widget.user.uid, {
        'fullName': _nameController.text.trim(),
        'age': _dobController.text.trim(),
        'gender': _gender,
        'mobile': _mobileController.text.trim(),
        'email': widget.user.email ?? '',
        'disclaimerAccepted': true,
        'verificationStatus': 'none',
        'isVerified': false,
      });

      final referralCode = _referralController.text.trim();
      if (referralCode.isNotEmpty && referralCode != widget.user.uid) {
        try {
          await _creditService.grantReferralBonus(referralCode, friendName: _nameController.text.trim());
          await _creditService.tryCompleteManualInvite(referralCode, phone: _mobileController.text.trim());
        } catch (_) {
          // Invalid/unknown referral code — this step still succeeds.
        }
      }
      // AuthGate reacts to the profile doc changing on its own — no
      // explicit navigation needed.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("सहेजने में समस्या आई। / Could not save. Try again."), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text("बुनियादी जानकारी / Basic Details"),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("बस कुछ ज़रूरी जानकारी / Just a few essentials",
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, color: AppColors.saffron), hintText: "पूरा नाम / Full Name"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "पूरा नाम भरना अनिवार्य है" : null,
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    validator: (v) => (v == null || v.isEmpty) ? "जन्म तिथि चुनें" : null,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000, 1, 1),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now().subtract(const Duration(days: 6570)),
                      );
                      if (picked != null) {
                        setState(() {
                          _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                        });
                      }
                    },
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.saffron, size: 20), hintText: "जन्म तिथि / DOB"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _gender.isNotEmpty ? _gender : null,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.people_outline, color: AppColors.saffron, size: 20), hintText: "लिंग / Gender"),
                    items: const [
                      DropdownMenuItem(value: "पुरुष / Male", child: Text("पुरुष / Male")),
                      DropdownMenuItem(value: "स्त्री / Female", child: Text("स्त्री / Female")),
                      DropdownMenuItem(value: "अन्य / Other", child: Text("अन्य / Other")),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? ''),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                readOnly: widget.user.phoneNumber != null,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined, color: AppColors.saffron), hintText: "मोबाइल नंबर / Mobile Number"),
                validator: (v) => (v == null || v.trim().length < 10) ? "सही मोबाइल नंबर डालें" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referralController,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.card_giftcard_outlined, color: AppColors.saffron), hintText: "रेफ़रल कोड (वैकल्पिक) / Referral code (optional)"),
              ),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(
                  value: _consent,
                  onChanged: (v) => setState(() { _consent = v ?? false; if (_consent) _consentError = false; }),
                  activeColor: AppColors.saffron,
                ),
                const Expanded(
                  child: Text(
                    "अस्वीकरण: हमारा कार्य केवल दो परिवारों को जोड़ना है। जाँच-पड़ताल की ज़िम्मेदारी आपकी है। किसी भी धोखाधड़ी के लिए हम उत्तरदायी नहीं हैं।",
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ),
              ]),
              if (_consentError)
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text("अस्वीकरण स्वीकार करना अनिवार्य है / You must accept to continue", style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("आगे बढ़ें / Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
