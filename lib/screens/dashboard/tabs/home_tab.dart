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
  String? _stateFilter;

  bool get _hasActiveFilters =>
      _religionFilter != null || _categoryFilter != null ||
      _genderFilter != null || _occupationFilter != null || _stateFilter != null;

  List<UserProfile> _applyFilters(List<UserProfile> profiles) {
    return profiles.where((p) {
      if (_religionFilter != null && !p.religion.contains(_religionFilter!)) return false;
      if (_categoryFilter != null && !p.category.contains(_categoryFilter!)) return false;
      if (_genderFilter != null && !p.gender.contains(_genderFilter!)) return false;
      if (_occupationFilter != null && !p.occupation.contains(_occupationFilter!)) return false;
      if (_stateFilter != null && p.state != _stateFilter) return false;
      return true;
    }).toList();
  }

  void _openFilterSheet() {
    String? religion = _religionFilter;
    String? category = _categoryFilter;
    String? gender = _genderFilter;
    String? occupation = _occupationFilter;
    String? state = _stateFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          Widget drop(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
            return DropdownButtonFormField<String>(
              isExpanded: true, value: value,
              decoration: InputDecoration(labelText: label),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text("सभी / All")),
                ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
              ],
              onChanged: (v) => setSheetState(() => onChanged(v)),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text("रिश्ते फ़िल्टर करें / Filter Matches", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              drop("धर्म / Religion", religion, const ["Hindu","Muslim","Sikh","Christian","Buddhist","Jain"], (v) => religion = v),
              const SizedBox(height: 12),
              drop("वर्ग / Category", category, const ["General","OBC","SC","ST"], (v) => category = v),
              const SizedBox(height: 12),
              drop("लिंग / Gender", gender, const ["Male","Female"], (v) => gender = v),
              const SizedBox(height: 12),
              drop("व्यवसाय / Occupation", occupation, const ["Job","Business","Farming","Self Employed","Student"], (v) => occupation = v),
              const SizedBox(height: 12),
              drop("राज्य / State", state, const ['उत्तर प्रदेश','मध्य प्रदेश','राजस्थान','बिहार','महाराष्ट्र','गुजरात','हरियाणा','पंजाब','दिल्ली','उत्तराखंड','हिमाचल प्रदेश','झारखंड','छत्तीसगढ़','ओडिशा','पश्चिम बंगाल','कर्नाटक','तमिलनाडु','केरल','तेलंगाना','आंध्र प्रदेश','असम','गोवा','अन्य / Other'], (v) => state = v),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => setSheetState(() { religion = null; category = null; gender = null; occupation = null; state = null; }),
                  child: const Text("साफ़ करें / Clear"))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    setState(() { _religionFilter = religion; _categoryFilter = category; _genderFilter = gender; _occupationFilter = occupation; _stateFilter = state; });
                    Navigator.pop(context);
                  },
                  child: const Text("लागू करें / Apply"))),
              ]),
            ]),
          );
        });
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
          return const Center(child: Text("अभी तक कोई नई प्रोफ़ाइल नहीं है। / No profiles yet."));
        }
        final allProfiles = snapshot.data!.docs
            .where((doc) => doc.id != currentUserId)
            .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
            .toList();
        final filteredProfiles = _applyFilters(allProfiles);
        if (allProfiles.isEmpty) {
          return const Center(child: Text("अभी कोई और उपयोगकर्ता नहीं। / No other users yet.", style: TextStyle(color: Colors.grey)));
        }
        return RefreshIndicator(
          color: kBrandColor,
          onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Expanded(child: Text("अनुशंसित रिश्ते / Recommended Matches",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandColor))),
                IconButton(
                  icon: Badge(isLabelVisible: _hasActiveFilters, smallSize: 9,
                      child: const Icon(Icons.filter_list, color: kBrandColor)),
                  onPressed: _openFilterSheet, tooltip: "फ़िल्टर / Filter"),
              ]),
              if (_hasActiveFilters && filteredProfiles.isEmpty)
                const Padding(padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text("इन फ़िल्टर से कोई प्रोफ़ाइल नहीं मिली। / No profiles match.", style: TextStyle(color: Colors.grey)))),
              const SizedBox(height: 10),
              ...filteredProfiles.map((profile) => _ProfileCard(currentUserId: currentUserId, profile: profile)),
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
  bool _alreadySent = false;

  @override
  void initState() { super.initState(); _checkStatus(); }

  Future<void> _checkStatus() async {
    final exists = await _interestService.hasExistingInterest(widget.currentUserId, widget.profile.uid);
    if (mounted) setState(() { _alreadySent = exists; _checking = false; });
  }

  Future<void> _sendInterest() async {
    setState(() => _checking = true);
    try {
      final exists = await _interestService.hasExistingInterest(widget.currentUserId, widget.profile.uid);
      if (exists) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("रुचि पहले से भेजी जा चुकी है। / Interest already sent.")));
      } else {
        final myDoc = await ProfileService().getUserProfile(widget.currentUserId);
        final myName = myDoc.data()?['fullName'] ?? 'Someone';
        await _interestService.sendInterest(fromUid: widget.currentUserId, fromName: myName, toUid: widget.profile.uid, toName: widget.profile.fullName);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${widget.profile.fullName} को रुचि भेज दी गई! 💌"), backgroundColor: Colors.green));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("रुचि भेजने में त्रुटि। / Error sending interest."), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _alreadySent = true; _checking = false; });
    }
  }

  void _reportUser(BuildContext context) {
    String selectedReason = 'fake';
    final detailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        title: const Text("रिपोर्ट करें / Report User"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("${widget.profile.fullName} को रिपोर्ट करें", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedReason,
            decoration: const InputDecoration(labelText: "कारण / Reason", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: "fake", child: Text("फ़र्ज़ी प्रोफ़ाइल / Fake Profile")),
              DropdownMenuItem(value: "spam", child: Text("स्पैम / Spam")),
              DropdownMenuItem(value: "inappropriate", child: Text("अनुचित व्यवहार / Inappropriate")),
              DropdownMenuItem(value: "fraud", child: Text("धोखाधड़ी / Fraud")),
              DropdownMenuItem(value: "other", child: Text("अन्य / Other")),
            ],
            onChanged: (v) => setDialogState(() => selectedReason = v ?? 'fake'),
          ),
          const SizedBox(height: 12),
          TextField(controller: detailCtrl, maxLines: 2,
            decoration: const InputDecoration(hintText: "विवरण / Details (optional)", border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("रद्द / Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('reports').add({
                  'reportedUid': widget.profile.uid,
                  'reportedName': widget.profile.fullName,
                  'reporterUid': widget.currentUserId,
                  'reason': selectedReason,
                  'details': detailCtrl.text,
                  'createdAt': DateTime.now(),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("रिपोर्ट भेज दी गई। धन्यवाद! / Report submitted."), backgroundColor: Colors.green));
                }
              } catch (_) {
                if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("रिपोर्ट नहीं भेजी जा सकी। / Report failed."), backgroundColor: Colors.red));
              }
            },
            child: const Text("रिपोर्ट करें / Report", style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    IconData avatarIcon = Icons.person;
    Color avatarColor = Colors.grey;
    if (profile.isFemale) { avatarIcon = Icons.face_3; avatarColor = Colors.pink; }
    else if (profile.isMale) { avatarIcon = Icons.face; avatarColor = Colors.blue; }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewProfileScreen(profile: profile))),
            child: Row(children: [
              CircleAvatar(radius: 32, backgroundColor: avatarColor.withOpacity(0.1), child: Icon(avatarIcon, size: 36, color: avatarColor)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(profile.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                  if (profile.isVerified) ...[const SizedBox(width: 4), const Icon(Icons.verified, size: 16, color: kBrandColor)],
                ]),
                const SizedBox(height: 4),
                Text("${profile.dob} • ${profile.religion}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 15, color: Colors.grey),
                  Expanded(child: Text(profile.location, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12.5))),
                ]),
              ])),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (v) { if (v == 'report') _reportUser(context); },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'report', child: Row(children: [
                    Icon(Icons.flag_outlined, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text("रिपोर्ट करें / Report", style: TextStyle(color: Colors.red)),
                  ])),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: SizedBox(height: 42,
              child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewProfileScreen(profile: profile))),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                child: const FittedBox(fit: BoxFit.scaleDown, child: Text("प्रोफ़ाइल देखें / View Profile", style: TextStyle(fontSize: 13)))))),
            const SizedBox(width: 10),
            Expanded(child: SizedBox(height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alreadySent ? Colors.grey.shade300 : kBrandColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(horizontal: 6)),
                onPressed: (_checking || _alreadySent) ? null : _sendInterest,
                child: FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_alreadySent ? Icons.check : Icons.favorite_border, size: 16, color: _alreadySent ? Colors.grey.shade700 : Colors.white),
                  const SizedBox(width: 6),
                  Text(_checking ? "..." : (_alreadySent ? "भेजा गया / Sent" : "रुचि भेजें / Send Interest"),
                    style: TextStyle(fontSize: 13, color: _alreadySent ? Colors.grey.shade700 : Colors.white)),
                ])))),
          ]),
        ]),
      ),
    );
  }
}
