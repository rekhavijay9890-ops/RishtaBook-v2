import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/interest_service.dart';
import '../../profile/view_profile_screen.dart';
import '../../../theme/app_theme.dart';

const Color kBrandColor = AppColors.primary;

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  String? _religionFilter;
  String? _categoryFilter;
  String? _genderFilter;
  String? _occupationFilter;

  bool get _hasActiveFilters =>
      _religionFilter != null ||
      _categoryFilter != null ||
      _genderFilter != null ||
      _occupationFilter != null;

  List<UserProfile> _applyFilters(List<UserProfile> profiles) {
    return profiles.where((p) {
      if (_religionFilter != null && p.religion != _religionFilter) return false;
      if (_categoryFilter != null && p.category != _categoryFilter) return false;
      if (_genderFilter != null && p.gender != _genderFilter) return false;
      if (_occupationFilter != null && p.occupation != _occupationFilter) return false;
      return true;
    }).toList();
  }

  void _openFilterSheet() {
    String? religion = _religionFilter;
    String? category = _categoryFilter;
    String? gender = _genderFilter;
    String? occupation = _occupationFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget filterDropdown(String label, String? value, List<String> options,
                ValueChanged<String?> onChanged) {
              return DropdownButtonFormField<String>(
                isExpanded: true,
                value: value,
                decoration: InputDecoration(labelText: label),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text("सभी / All")),
                  ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
                ],
                onChanged: (v) => setSheetState(() => onChanged(v)),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("फ़िल्टर करें", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  filterDropdown("धर्म / Religion", religion, const ["हिन्दू / Hindu", "मुस्लिम / Muslim", "सिख / Sikh", "ईसाई / Christian"],
                      (v) => religion = v),
                  const SizedBox(height: 12),
                  filterDropdown("वर्ग / Category", category,
                      const ["सामान्य / General", "ओबीसी", "एससी", "एसटी", "अन्य / Other"], (v) => category = v),
                  const SizedBox(height: 12),
                  filterDropdown(
                      "लिंग / Gender", gender, const ["पुरुष / Male", "स्त्री / Female", "अन्य / Other"], (v) => gender = v),
                  const SizedBox(height: 12),
                  filterDropdown("व्यवसाय / Occupation", occupation,
                      const ["नौकरी / Job", "व्यापार / Business", "खेती / Farming", "अन्य / Other"], (v) => occupation = v),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              religion = null;
                              category = null;
                              gender = null;
                              occupation = null;
                            });
                          },
                          child: const Text("हटाएँ"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _religionFilter = religion;
                              _categoryFilter = category;
                              _genderFilter = gender;
                              _occupationFilter = occupation;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("लागू करें / Apply"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _profileService.allProfilesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBrandColor));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("अभी तक कोई नई प्रोफ़ाइल नहीं है।"));
        }

        final allProfiles = snapshot.data!.docs
            .where((doc) => doc.id != currentUserId)
            .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
            .toList();

        final filteredProfiles = _applyFilters(allProfiles);

        if (allProfiles.isEmpty) {
          return const Center(
              child: Text("अभी आपके अलावा कोई नहीं है। / No other users yet.",
                  style: TextStyle(color: Colors.grey)));
        }

        return RefreshIndicator(
          color: kBrandColor,
          onRefresh: () async {
            // The list is already realtime via the Firestore stream; this
            // just gives the pull-to-refresh gesture a visible response.
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("अनुशंसित रिश्ते / Recommended Matches",
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: kBrandColor)),
                  IconButton(
                    icon: Badge(
                      isLabelVisible: _hasActiveFilters,
                      smallSize: 9,
                      child: const Icon(Icons.filter_list, color: kBrandColor),
                    ),
                    onPressed: _openFilterSheet,
                    tooltip: "फ़िल्टर / Filter",
                  ),
                ],
              ),
              if (allProfiles.isनहींtEmpty && filteredProfiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text("इन फ़िल्टर से कोई प्रोफ़ाइल नहीं मिली। / No profiles match these filters.",
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              const SizedBox(height: 15),
              ...filteredProfiles.map((profile) =>
                  _ProfileCard(currentUserId: currentUserId, profile: profile)),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatefulWidget {
  final String currentUserId;
  final UserProfile profile;
  const _ProfileCard({required this.currentUserId, required this.profile});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  final InterestService _interestService = InterestService();
  bool _checking = true;
  bool _alreadyभेजी गई = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final exists = await _interestService.hasExistingInterest(
        widget.currentUserId, widget.profile.uid);
    if (mounted) setState(() {
      _alreadyभेजी गई = exists;
      _checking = false;
    });
  }

  Future<void> _sendInterest() async {
    setState(() => _checking = true);
    try {
      final exists = await _interestService.hasExistingInterest(
          widget.currentUserId, widget.profile.uid);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("रुचि / Interest पहले से भेजी जा चुकी है।")));
        }
      } else {
        // Fetch our own name for the interest record.
        final myDoc = await ProfileService().getUserProfile(widget.currentUserId);
        final myName = myDoc.data()?['fullName'] ?? 'Someone';
        await _interestService.sendInterest(
          fromUid: widget.currentUserId,
          fromName: myName,
          toUid: widget.profile.uid,
          toName: widget.profile.fullName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("${widget.profile.fullName} को रुचि भेज दी गई! 💌"),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("रुचि भेजने में त्रुटि / Error sending interest."), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() {
        _alreadyभेजी गई = true;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    IconData avatarIcon = Icons.person;
    Color avatarColor = Colors.grey;
    if (profile.isFemale) {
      avatarIcon = Icons.face_3;
      avatarColor = Colors.pink;
    } else if (profile.isMale) {
      avatarIcon = Icons.face;
      avatarColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ViewProfileScreen(profile: profile))),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 32,
                      backgroundColor: avatarColor.withOpacity(0.1),
                      child: Icon(avatarIcon, size: 36, color: avatarColor)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                              child: Text(profile.fullName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.bold))),
                          if (profile.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 16, color: kBrandColor),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text("${profile.dob} • ${profile.religion}",
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on, size: 15, color: Colors.grey),
                          Expanded(
                            child: Text(profile.location,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ViewProfileScreen(profile: profile))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("प्रोफ़ाइल देखें / View Profile", style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _alreadyभेजी गई ? Colors.grey.shade300 : kBrandColor,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      onPressed: (_checking || _alreadyभेजी गई) ? null : _sendInterest,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_alreadyभेजी गई ? Icons.check : Icons.favorite_border,
                                size: 16, color: _alreadyभेजी गई ? Colors.grey.shade700 : Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              _checking ? "..." : (_alreadyभेजी गई ? "भेजी गई" : "रुचि भेजें / Send Interest"),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _alreadyभेजी गई ? Colors.grey.shade700 : Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
