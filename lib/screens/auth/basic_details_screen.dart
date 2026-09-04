import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import '../../widgets/rb_gradient_app_bar.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/credit_service.dart';
import '../../i18n/strings.dart';

/// Short, mandatory step shown right after ANY successful sign-in
/// (Google, Mobile, or Email) whose profile is missing these fields —
/// closes the gap where Google sign-in used to skip both the basic-info
/// step AND the disclaimer/consent that email signup always required.
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

      final enteredCode = _referralController.text.trim();
      if (enteredCode.isNotEmpty) {
        try {
          final referrerUid = await _profileService.findUidByReferralCode(enteredCode);
          if (referrerUid != null && referrerUid != widget.user.uid) {
            await _creditService.grantReferralBonus(referrerUid, friendName: _nameController.text.trim());
            await _creditService.tryCompleteManualInvite(referrerUid, phone: _mobileController.text.trim());
          }
        } catch (_) {
          // Invalid/unknown referral code — this step still succeeds.
        }
      }
      // AuthGate reacts to the profile doc changing on its own — no
      // explicit navigation needed.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('basicDetails.saveError')), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gender is stored as a fixed bilingual value regardless of the
    // display language, so the value used for matching (UserProfile.
    // isFemale/isMale) and any pre-redesign accounts already using this
    // format stay consistent - only the label shown to the user changes
    // with the toggle.
    const genderMaleValue = "पुरुष / Male";
    const genderFemaleValue = "स्त्री / Female";
    const genderOtherValue = "अन्य / Other";

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: RbGradientAppBar(
        title: Text(context.t('basicDetails.title')),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.t('basicDetails.wrongAccount'),
          onPressed: () => AuthService().signOut(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.t('basicDetails.subtitle'), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.person_outline, color: AppColors.saffron), hintText: context.t('basicDetails.fullNameHint')),
                validator: (v) => (v == null || v.trim().isEmpty) ? context.t('basicDetails.fullNameRequired') : null,
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    validator: (v) => (v == null || v.isEmpty) ? context.t('basicDetails.dobRequired') : null,
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
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.saffron, size: 20), hintText: context.t('basicDetails.dobHint')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _gender.isNotEmpty ? _gender : null,
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.people_outline, color: AppColors.saffron, size: 20), hintText: context.t('basicDetails.genderHint')),
                    items: [
                      DropdownMenuItem(value: genderMaleValue, child: Text(context.t('basicDetails.genderMale'))),
                      DropdownMenuItem(value: genderFemaleValue, child: Text(context.t('basicDetails.genderFemale'))),
                      DropdownMenuItem(value: genderOtherValue, child: Text(context.t('basicDetails.genderOther'))),
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
                decoration: InputDecoration(prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.saffron), hintText: context.t('basicDetails.mobileHint')),
                validator: (v) => (v == null || v.trim().length < 10) ? context.t('basicDetails.mobileRequired') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referralController,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.card_giftcard_outlined, color: AppColors.saffron), hintText: context.t('basicDetails.referralHint')),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() { _consent = !_consent; if (_consent) _consentError = false; }),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _consentError ? AppColors.error : Colors.transparent, width: 1.2),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Checkbox(
                      value: _consent,
                      onChanged: (v) => setState(() { _consent = v ?? false; if (_consent) _consentError = false; }),
                      activeColor: AppColors.saffron,
                    ),
                    Expanded(
                      child: Text(
                        context.t('basicDetails.disclaimer'),
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                    ),
                  ]),
                ),
              ),
              if (_consentError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(context.t('basicDetails.consentError'), style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(context.t('basicDetails.continue')),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
