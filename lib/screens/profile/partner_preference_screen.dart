import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../models/partner_preferences.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../i18n/strings.dart';

/// What the signed-in user is looking for in a match. Feeds
/// MatchmakingService's scoring on Home/Search - this is a ranking
/// signal, not a hard filter, so every field defaults to "any" and
/// leaving it that way just means that criterion doesn't move the score.
class PartnerPreferenceScreen extends StatefulWidget {
  final String uid;
  const PartnerPreferenceScreen({super.key, required this.uid});

  @override
  State<PartnerPreferenceScreen> createState() => _PartnerPreferenceScreenState();
}

class _PartnerPreferenceScreenState extends State<PartnerPreferenceScreen> {
  final _profileService = ProfileService();
  bool _loading = true;
  bool _saving = false;
  PartnerPreferences _prefs = PartnerPreferences.defaults();

  static const _religionValues = [
    'हिन्दू / Hindu', 'मुस्लिम / Muslim', 'सिख / Sikh',
    'ईसाई / Christian', 'बौद्ध / Buddhist', 'जैन / Jain', 'अन्य / Other',
  ];
  static const _religionKeys = [
    'completeProfile.religion.hindu', 'completeProfile.religion.muslim', 'completeProfile.religion.sikh',
    'completeProfile.religion.christian', 'completeProfile.religion.buddhist', 'completeProfile.religion.jain',
    'completeProfile.religion.other',
  ];
  static const _maritalValues = ['never_married', 'divorced', 'widowed', 'awaiting_divorce'];
  static const _maritalKeys = [
    'maritalStatus.neverMarried', 'maritalStatus.divorced', 'maritalStatus.widowed', 'maritalStatus.awaitingDivorce',
  ];
  static const _educationValues = ['high_school', 'diploma', 'bachelors', 'masters', 'doctorate', 'other'];
  static const _educationKeys = [
    'education.highSchool', 'education.diploma', 'education.bachelors', 'education.masters', 'education.doctorate', 'education.other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await _profileService.getUserProfile(widget.uid);
    final data = doc.data();
    setState(() {
      _prefs = PartnerPreferences.fromMap(data?['preferences'] as Map<String, dynamic>?);
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _profileService.updateUserProfile(widget.uid, {'preferences': _prefs.toMap()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('partnerPref.saved')), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('partnerPref.saveError')), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _multiSelectChips({
    required List<String> values,
    required List<String> keys,
    required List<String> selected,
    required void Function(List<String>) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(values.length, (i) {
        final value = values[i];
        final label = context.t(keys[i]);
        final isSelected = selected.contains(value);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: AppColors.safLight,
          checkmarkColor: AppColors.saffron,
          onSelected: (sel) {
            final next = List<String>.from(selected);
            if (sel) {
              next.add(value);
            } else {
              next.remove(value);
            }
            onChanged(next);
          },
        );
      }),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffron, fontSize: 14)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Text(context.t('partnerPref.title')),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.saffron))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(context.t('partnerPref.subtitle'), style: const TextStyle(fontSize: 12, color: AppColors.muted)),

                _section(context.t('partnerPref.ageRange')),
                Text('${_prefs.ageMin} - ${_prefs.ageMax}', style: const TextStyle(fontWeight: FontWeight.w700)),
                RangeSlider(
                  min: 18, max: 70, divisions: 52,
                  values: RangeValues(_prefs.ageMin.toDouble(), _prefs.ageMax.toDouble()),
                  activeColor: AppColors.saffron,
                  labels: RangeLabels('${_prefs.ageMin}', '${_prefs.ageMax}'),
                  onChanged: (v) => setState(() => _prefs = _prefs.copyWith(ageMin: v.start.round(), ageMax: v.end.round())),
                ),

                _section(context.t('partnerPref.heightRange')),
                Builder(builder: (context) {
                  String fmt(int cm) {
                    final inches = (cm / 2.54).round();
                    return "${inches ~/ 12}'${inches % 12}\"";
                  }
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${fmt(_prefs.heightMinCm)} - ${fmt(_prefs.heightMaxCm)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    RangeSlider(
                      min: 120, max: 210, divisions: 90,
                      values: RangeValues(_prefs.heightMinCm.toDouble(), _prefs.heightMaxCm.toDouble()),
                      activeColor: AppColors.saffron,
                      labels: RangeLabels(fmt(_prefs.heightMinCm), fmt(_prefs.heightMaxCm)),
                      onChanged: (v) => setState(() => _prefs = _prefs.copyWith(heightMinCm: v.start.round(), heightMaxCm: v.end.round())),
                    ),
                  ]);
                }),

                _section(context.t('partnerPref.religion')),
                _multiSelectChips(
                  values: _religionValues, keys: _religionKeys, selected: _prefs.religions,
                  onChanged: (v) => setState(() => _prefs = _prefs.copyWith(religions: v)),
                ),

                _section(context.t('partnerPref.maritalStatus')),
                _multiSelectChips(
                  values: _maritalValues, keys: _maritalKeys, selected: _prefs.maritalStatuses,
                  onChanged: (v) => setState(() => _prefs = _prefs.copyWith(maritalStatuses: v)),
                ),

                _section(context.t('partnerPref.education')),
                _multiSelectChips(
                  values: _educationValues, keys: _educationKeys, selected: _prefs.educations,
                  onChanged: (v) => setState(() => _prefs = _prefs.copyWith(educations: v)),
                ),

                _section(context.t('partnerPref.state')),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: kIndianStates.map((s) {
                    final label = context.isHindi ? s.$1 : s.$2;
                    final isSelected = _prefs.states.contains(s.$1);
                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppColors.safLight,
                      checkmarkColor: AppColors.saffron,
                      onSelected: (sel) {
                        final next = List<String>.from(_prefs.states);
                        if (sel) { next.add(s.$1); } else { next.remove(s.$1); }
                        setState(() => _prefs = _prefs.copyWith(states: next));
                      },
                    );
                  }).toList(),
                ),

                _section(context.t('partnerPref.manglik')),
                Wrap(spacing: 8, children: [
                  ChoiceChip(
                    label: Text(context.t('partnerPref.manglikAny')),
                    selected: _prefs.manglik == 'any',
                    selectedColor: AppColors.safLight,
                    onSelected: (_) => setState(() => _prefs = _prefs.copyWith(manglik: 'any')),
                  ),
                  ChoiceChip(
                    label: Text(context.t('kundali.yes')),
                    selected: _prefs.manglik == 'yes',
                    selectedColor: AppColors.safLight,
                    onSelected: (_) => setState(() => _prefs = _prefs.copyWith(manglik: 'yes')),
                  ),
                  ChoiceChip(
                    label: Text(context.t('kundali.no')),
                    selected: _prefs.manglik == 'no',
                    selectedColor: AppColors.safLight,
                    onSelected: (_) => setState(() => _prefs = _prefs.copyWith(manglik: 'no')),
                  ),
                ]),

                const SizedBox(height: 26),
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
    );
  }
}
