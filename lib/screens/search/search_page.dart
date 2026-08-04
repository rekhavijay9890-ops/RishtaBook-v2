import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/credit_service.dart';
import '../../i18n/strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/rb_avatar.dart';
import '../../widgets/rb_badge.dart';
import '../profile/view_profile_screen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ProfileService _profileService = ProfileService();
  final CreditService _creditService = CreditService();
  final AuthService _authService = AuthService();

  String? _religion, _category, _gender, _occupation, _state;
  final _searchCtrl = TextEditingController();

  bool get _hasFilters => _religion != null || _category != null || _gender != null || _occupation != null || _state != null;

  List<UserProfile> _apply(List<UserProfile> profiles) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return profiles.where((p) {
      if (_religion != null && !p.religion.contains(_religion!)) return false;
      if (_category != null && !p.category.contains(_category!)) return false;
      if (_gender != null && !p.gender.contains(_gender!)) return false;
      if (_occupation != null && !p.occupation.contains(_occupation!)) return false;
      if (_state != null && p.state != _state) return false;
      if (q.isNotEmpty &&
          !p.fullName.toLowerCase().contains(q) &&
          !p.location.toLowerCase().contains(q) &&
          !p.occupation.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _openFilterSheet() {
    String? religion = _religion, category = _category, gender = _gender, occupation = _occupation, state = _state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        Widget drop(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
          return DropdownButtonFormField<String>(
            isExpanded: true,
            value: value,
            decoration: InputDecoration(labelText: label),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('All')),
              ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
            ],
            onChanged: (v) => setSheetState(() => onChanged(v)),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.t('search.filters'), style: AppText.headingLarge),
            const SizedBox(height: 16),
            drop('Religion', religion, const ['Hindu', 'Muslim', 'Sikh', 'Christian', 'Buddhist', 'Jain'], (v) => religion = v),
            const SizedBox(height: 12),
            drop('Category', category, const ['General', 'OBC', 'SC', 'ST'], (v) => category = v),
            const SizedBox(height: 12),
            drop('Gender', gender, const ['Male', 'Female'], (v) => gender = v),
            const SizedBox(height: 12),
            drop('Occupation', occupation, const ['Job', 'Business', 'Farming', 'Self Employed', 'Student'], (v) => occupation = v),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setSheetState(() { religion = null; category = null; gender = null; occupation = null; state = null; }),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() { _religion = religion; _category = category; _gender = gender; _occupation = occupation; _state = state; });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ]),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          Container(
            color: AppColors.headerBg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Text(context.t('search.title'), style: AppText.headerTitle)),
                    GestureDetector(
                      onTap: _openFilterSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(100)),
                        child: Text(context.t('search.filters'), style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(children: [
                      const Text('🔍', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            filled: false,
                            hintText: context.t('search.hint'),
                            hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _profileService.userProfileStream(uid),
              builder: (context, meSnap) {
                final unlockedUids = List<String>.from(meSnap.data?.data()?['unlockedProfileUids'] ?? []);
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _profileService.allProfilesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
                    }
                    final all = (snapshot.data?.docs ?? [])
                        .where((doc) => doc.id != uid)
                        .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
                        .toList();
                    final results = _apply(all);
                    return ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (_hasFilters)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Wrap(spacing: 6, runSpacing: 6, children: [
                              for (final f in [_religion, _category, _gender, _occupation, _state].whereType<String>())
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.saffron, borderRadius: BorderRadius.circular(100)),
                                  child: Text(f, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                            ]),
                          ),
                        Text(context.t('search.found', [results.length]), style: AppText.caption),
                        const SizedBox(height: 12),
                        for (var i = 0; i < results.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ResultTile(
                              profile: results[i],
                              locked: i >= CreditService.freeSearchPreviewCount && !unlockedUids.contains(results[i].uid),
                              onUnlock: () async {
                                final ok = await _creditService.unlockProfile(uid, targetUid: results[i].uid, targetName: results[i].fullName);
                                if (!context.mounted) return;
                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('chat.insufficientCredits'))));
                                }
                              },
                              onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProfileScreen(profile: results[i]))),
                              onChat: () => Navigator.pushNamed(context, '/root'),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final UserProfile profile;
  final bool locked;
  final VoidCallback onUnlock;
  final VoidCallback onOpen;
  final VoidCallback onChat;

  const _ResultTile({required this.profile, required this.locked, required this.onUnlock, required this.onOpen, required this.onChat});

  @override
  Widget build(BuildContext context) {
    final color = profile.isFemale ? AppColors.rose : (profile.isMale ? AppColors.teal : AppColors.saffron);
    return Opacity(
      opacity: locked ? 0.7 : 1,
      child: GestureDetector(
        onTap: locked ? null : onOpen,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
          child: Row(children: [
            locked
                ? Container(width: 46, height: 46, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.borderColor), child: const Center(child: Text('🔒', style: TextStyle(fontSize: 20))))
                : RbAvatar(initials: profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?', size: 46, color: color, photoUrl: profile.primaryPhotoUrl),
            const SizedBox(width: 10),
            Expanded(
              child: locked
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(context.t('search.hidden'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(context.t('search.unlockHint'), style: AppText.caption),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(profile.fullName, style: AppText.headingMedium, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 1),
                      Text('${profile.occupation} · ${profile.location}', style: AppText.bodySmall, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Wrap(spacing: 5, children: [
                        if (profile.isVerified) RbBadge(text: context.t('common.verified'), color: AppColors.teal),
                      ]),
                    ]),
            ),
            locked
                ? GestureDetector(
                    onTap: onUnlock,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.saffron, borderRadius: BorderRadius.circular(100)),
                      child: Text(context.t('search.unlock'), style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  )
                : GestureDetector(
                    onTap: onChat,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealLight),
                      child: const Center(child: Text('💬', style: TextStyle(fontSize: 14))),
                    ),
                  ),
          ]),
        ),
      ),
    );
  }
}
