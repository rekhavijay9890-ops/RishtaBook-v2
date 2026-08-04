import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../config/constants.dart';
import '../../services/profile_service.dart';
import '../../services/kundali_service.dart';

/// The extended profile fields (religion, caste, address, family, kundali)
/// beyond what [BasicDetailsScreen] collects. Reached either right after
/// signup (via ProfileChoiceScreen -> "Complete now") or later, any time,
/// from the Profile tab's edit entry — same screen, same upsert semantics.
class CompleteProfileScreen extends StatefulWidget {
  final String uid;
  const CompleteProfileScreen({super.key, required this.uid});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _profileService = ProfileService();
  bool _loading = true;
  bool _saving = false;

  final _religionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _casteController = TextEditingController();
  final _gotraController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _occupationController = TextEditingController();
  final _brothersController = TextEditingController();
  final _sistersController = TextEditingController();
  final _familyDetailsController = TextEditingController();
  final _requirementsController = TextEditingController();
  String _rashi = '';
  String _nakshatra = '';
  String _manglik = 'no';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await _profileService.getUserProfile(widget.uid);
    final data = doc.data() ?? {};
    _religionController.text = data['religion'] ?? '';
    _categoryController.text = data['category'] ?? '';
    _casteController.text = data['caste'] ?? '';
    _gotraController.text = data['gotra'] ?? '';
    _villageController.text = data['village'] ?? '';
    _districtController.text = data['district'] ?? '';
    _stateController.text = data['state'] ?? '';
    _occupationController.text = data['occupation'] ?? '';
    _brothersController.text = data['brothers'] ?? '';
    _sistersController.text = data['sisters'] ?? '';
    _familyDetailsController.text = data['familyDetails'] ?? '';
    _requirementsController.text = data['requirements'] ?? '';
    _rashi = data['rashi'] ?? '';
    _nakshatra = data['nakshatra'] ?? '';
    _manglik = data['manglik'] ?? 'no';
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [
      _religionController, _categoryController, _casteController, _gotraController,
      _villageController, _districtController, _stateController, _occupationController,
      _brothersController, _sistersController, _familyDetailsController, _requirementsController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _profileService.updateUserProfile(widget.uid, {
        'religion': _religionController.text.trim(),
        'category': _categoryController.text.trim(),
        'caste': _casteController.text.trim(),
        'gotra': _gotraController.text.trim(),
        'village': _villageController.text.trim(),
        'district': _districtController.text.trim(),
        'state': _stateController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'brothers': _brothersController.text.trim(),
        'sisters': _sistersController.text.trim(),
        'familyDetails': _familyDetailsController.text.trim(),
        'requirements': _requirementsController.text.trim(),
        'rashi': _rashi,
        'nakshatra': _nakshatra,
        'manglik': _manglik,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("प्रोफ़ाइल सहेजी गई / Profile saved"), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("सहेजने में समस्या आई। / Could not save."), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String hint, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(controller: controller, maxLines: maxLines, decoration: InputDecoration(hintText: hint));
  }

  Widget _dropdown(String hint, List<String> items, TextEditingController controller) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: controller.text.isNotEmpty && items.contains(controller.text) ? controller.text : null,
      decoration: InputDecoration(hintText: hint),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) => setState(() => controller.text = v ?? ''),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffron, fontSize: 14.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text("प्रोफ़ाइल पूरी करें / Complete Profile"),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.saffron))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader("🛕 धर्म एवं समाज / Religion & Community"),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _dropdown("धर्म / Religion", const ["हिन्दू / Hindu", "मुस्लिम / Muslim", "सिख / Sikh", "ईसाई / Christian", "बौद्ध / Buddhist", "जैन / Jain", "अन्य / Other"], _religionController)),
                    const SizedBox(width: 12),
                    Expanded(child: _dropdown("वर्ग / Category", const ["सामान्य / General", "OBC", "SC", "ST", "अन्य / Other"], _categoryController)),
                  ]),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _field("जाति / Caste", _casteController)),
                    const SizedBox(width: 12),
                    Expanded(child: _field("गोत्र / Gotra", _gotraController)),
                  ]),
                  _sectionHeader("📍 पता / Address"),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _field("गाँव / Village or Town", _villageController)),
                    const SizedBox(width: 12),
                    Expanded(child: _field("जिला / District", _districtController)),
                  ]),
                  const SizedBox(height: 12),
                  _dropdown("राज्य / State", kIndianStates, _stateController),
                  _sectionHeader("💼 व्यवसाय / Occupation"),
                  _dropdown("व्यवसाय / Occupation", const ["नौकरी / Job", "व्यापार / Business", "खेती / Farming", "स्वरोजगार / Self Employed", "विद्यार्थी / Student", "अन्य / Other"], _occupationController),
                  _sectionHeader("👨‍👩‍👧‍👦 पारिवारिक जानकारी / Family Details"),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _field("भाइयों की संख्या / No. of Brothers", _brothersController)),
                    const SizedBox(width: 12),
                    Expanded(child: _field("बहनों की संख्या / No. of Sisters", _sistersController)),
                  ]),
                  const SizedBox(height: 12),
                  _field("पारिवारिक विवरण / Family Details", _familyDetailsController, maxLines: 2),
                  _sectionHeader("💑 जीवनसाथी की अपेक्षाएँ / Partner Preference"),
                  _field("कोई विशेष शर्त / Any preference", _requirementsController, maxLines: 2),
                  _sectionHeader("⭐ कुंडली (वैकल्पिक) / Kundali (optional)"),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _rashi.isNotEmpty ? _rashi : null,
                        decoration: const InputDecoration(hintText: "राशि / Rashi"),
                        items: KundaliService.rashis.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _rashi = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _nakshatra.isNotEmpty ? _nakshatra : null,
                        decoration: const InputDecoration(hintText: "नक्षत्र / Nakshatra"),
                        items: KundaliService.nakshatras.map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _nakshatra = v ?? ''),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _manglik,
                    decoration: const InputDecoration(hintText: "मांगलिक / Manglik"),
                    items: const [
                      DropdownMenuItem(value: 'no', child: Text('नहीं / No')),
                      DropdownMenuItem(value: 'yes', child: Text('हाँ / Yes')),
                    ],
                    onChanged: (v) => setState(() => _manglik = v ?? 'no'),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("सहेजें / Save"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
