import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../config/constants.dart';
import '../../services/profile_service.dart';
import '../../services/kundali_service.dart';
import '../../i18n/strings.dart';

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
  int _heightCm = 170;
  String _maritalStatus = 'never_married';
  String _education = '';
  final _motherTongueController = TextEditingController();
  String _incomeBand = '';

  static const _incomeOptions = [
    ('below_3', 'income.below3'),
    ('3_6', 'income.3to6'),
    ('6_10', 'income.6to10'),
    ('10_20', 'income.10to20'),
    ('above_20', 'income.above20'),
  ];

  static const _maritalStatusOptions = [
    ('never_married', 'maritalStatus.neverMarried'),
    ('divorced', 'maritalStatus.divorced'),
    ('widowed', 'maritalStatus.widowed'),
    ('awaiting_divorce', 'maritalStatus.awaitingDivorce'),
  ];
  static const _educationOptions = [
    ('high_school', 'education.highSchool'),
    ('diploma', 'education.diploma'),
    ('bachelors', 'education.bachelors'),
    ('masters', 'education.masters'),
    ('doctorate', 'education.doctorate'),
    ('other', 'education.other'),
  ];

  // Dropdowns store a fixed bilingual value (unchanged regardless of
  // display language) so existing saved profiles and any other code
  // reading these fields stay consistent - only the label shown to the
  // user switches with the toggle. See _religionOptions/_categoryOptions/
  // _occupationOptions below for the value<->label pairing.
  static const _religionOptions = [
    ('हिन्दू / Hindu', 'completeProfile.religion.hindu'),
    ('मुस्लिम / Muslim', 'completeProfile.religion.muslim'),
    ('सिख / Sikh', 'completeProfile.religion.sikh'),
    ('ईसाई / Christian', 'completeProfile.religion.christian'),
    ('बौद्ध / Buddhist', 'completeProfile.religion.buddhist'),
    ('जैन / Jain', 'completeProfile.religion.jain'),
    ('अन्य / Other', 'completeProfile.religion.other'),
  ];
  static const _categoryOptions = [
    ('सामान्य / General', 'completeProfile.category.general'),
    ('OBC', null),
    ('SC', null),
    ('ST', null),
    ('अन्य / Other', 'completeProfile.category.other'),
  ];
  static const _occupationOptions = [
    ('नौकरी / Job', 'completeProfile.occupation.job'),
    ('व्यापार / Business', 'completeProfile.occupation.business'),
    ('खेती / Farming', 'completeProfile.occupation.farming'),
    ('स्वरोजगार / Self Employed', 'completeProfile.occupation.selfEmployed'),
    ('विद्यार्थी / Student', 'completeProfile.occupation.student'),
    ('अन्य / Other', 'completeProfile.occupation.other'),
  ];

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
    _heightCm = (data['heightCm'] as num?)?.toInt() ?? 170;
    _maritalStatus = data['maritalStatus'] ?? 'never_married';
    _education = data['education'] ?? '';
    _motherTongueController.text = data['motherTongue'] ?? '';
    _incomeBand = data['incomeBand'] ?? '';
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [
      _religionController, _categoryController, _casteController, _gotraController,
      _villageController, _districtController, _stateController, _occupationController,
      _brothersController, _sistersController, _familyDetailsController, _requirementsController,
      _motherTongueController,
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
        'heightCm': _heightCm,
        'maritalStatus': _maritalStatus,
        'education': _education,
        'motherTongue': _motherTongueController.text.trim(),
        'incomeBand': _incomeBand,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('completeProfile.saved')), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('completeProfile.saveError')), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String hint, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(controller: controller, maxLines: maxLines, decoration: InputDecoration(hintText: hint));
  }

  Widget _bilingualDropdown(String hint, List<(String, String?)> options, TextEditingController controller) {
    final values = options.map((o) => o.$1).toList();
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: controller.text.isNotEmpty && values.contains(controller.text) ? controller.text : null,
      decoration: InputDecoration(hintText: hint),
      items: options.map((o) {
        final label = o.$2 != null ? context.t(o.$2!) : o.$1;
        return DropdownMenuItem(value: o.$1, child: Text(label, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: (v) => setState(() => controller.text = v ?? ''),
    );
  }

  /// Value stored/matched is always the Hindi name (kIndianStates.$1) so
  /// existing saved profiles keep working - only the label shown switches
  /// with the toggle.
  Widget _stateDropdown(String hint, TextEditingController controller) {
    final values = kIndianStates.map((s) => s.$1).toList();
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: controller.text.isNotEmpty && values.contains(controller.text) ? controller.text : null,
      decoration: InputDecoration(hintText: hint),
      items: kIndianStates.map((s) {
        final label = context.isHindi ? s.$1 : s.$2;
        return DropdownMenuItem(value: s.$1, child: Text(label, overflow: TextOverflow.ellipsis));
      }).toList(),
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
        title: Text(context.t('completeProfile.title')),
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
                  _sectionHeader("🛕 ${context.t('completeProfile.religionSection')}"),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _bilingualDropdown(context.t('completeProfile.religionHint'), _religionOptions, _religionController)),
                    const SizedBox(width: 12),
                    Expanded(child: _bilingualDropdown(context.t('completeProfile.categoryHint'), _categoryOptions, _categoryController)),
                  ]),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _field(context.t('completeProfile.casteHint'), _casteController)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(context.t('completeProfile.gotraHint'), _gotraController)),
                  ]),
                  _sectionHeader("📍 ${context.t('completeProfile.addressSection')}"),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _field(context.t('completeProfile.villageHint'), _villageController)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(context.t('completeProfile.districtHint'), _districtController)),
                  ]),
                  const SizedBox(height: 12),
                  _stateDropdown(context.t('completeProfile.stateHint'), _stateController),
                  _sectionHeader("💼 ${context.t('completeProfile.occupationSection')}"),
                  _bilingualDropdown(context.t('completeProfile.occupationHint'), _occupationOptions, _occupationController),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _education.isNotEmpty ? _education : null,
                    decoration: InputDecoration(hintText: context.t('completeProfile.educationHint')),
                    items: _educationOptions.map((o) => DropdownMenuItem(value: o.$1, child: Text(context.t(o.$2)))).toList(),
                    onChanged: (v) => setState(() => _education = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      flex: 2,
                      child: Builder(builder: (context) {
                        final inches = (_heightCm / 2.54).round();
                        final display = "${inches ~/ 12}'${inches % 12}\" ($_heightCm cm)";
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("${context.t('completeProfile.heightHint')}: $display", style: const TextStyle(fontSize: 12.5)),
                          Slider(
                            min: 120, max: 210,
                            value: _heightCm.toDouble(),
                            activeColor: AppColors.saffron,
                            label: display,
                            onChanged: (v) => setState(() => _heightCm = v.round()),
                          ),
                        ]);
                      }),
                    ),
                  ]),
                  DropdownButtonFormField<String>(
                    value: _maritalStatus,
                    decoration: InputDecoration(hintText: context.t('completeProfile.maritalStatusHint')),
                    items: _maritalStatusOptions.map((o) => DropdownMenuItem(value: o.$1, child: Text(context.t(o.$2)))).toList(),
                    onChanged: (v) => setState(() => _maritalStatus = v ?? 'never_married'),
                  ),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _field(context.t('completeProfile.motherTongueHint'), _motherTongueController)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _incomeBand.isNotEmpty ? _incomeBand : null,
                        decoration: InputDecoration(hintText: context.t('completeProfile.incomeHint')),
                        items: _incomeOptions.map((o) => DropdownMenuItem(value: o.$1, child: Text(context.t(o.$2), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _incomeBand = v ?? ''),
                      ),
                    ),
                  ]),
                  _sectionHeader("👨‍👩‍👧‍👦 ${context.t('completeProfile.familySection')}"),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _field(context.t('completeProfile.brothersHint'), _brothersController)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(context.t('completeProfile.sistersHint'), _sistersController)),
                  ]),
                  const SizedBox(height: 12),
                  _field(context.t('completeProfile.familyDetailsHint'), _familyDetailsController, maxLines: 2),
                  _sectionHeader("💑 ${context.t('completeProfile.preferenceSection')}"),
                  _field(context.t('completeProfile.requirementsHint'), _requirementsController, maxLines: 2),
                  _sectionHeader("⭐ ${context.t('completeProfile.kundaliSection')}"),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _rashi.isNotEmpty ? _rashi : null,
                        decoration: InputDecoration(hintText: context.t('completeProfile.rashiHint')),
                        items: KundaliService.rashis.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _rashi = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _nakshatra.isNotEmpty ? _nakshatra : null,
                        decoration: InputDecoration(hintText: context.t('completeProfile.nakshatraHint')),
                        items: KundaliService.nakshatras.map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _nakshatra = v ?? ''),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _manglik,
                    decoration: InputDecoration(hintText: context.t('completeProfile.manglikHint')),
                    items: [
                      DropdownMenuItem(value: 'no', child: Text(context.t('kundali.no'))),
                      DropdownMenuItem(value: 'yes', child: Text(context.t('kundali.yes'))),
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
                          : Text(context.t('common.save')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
