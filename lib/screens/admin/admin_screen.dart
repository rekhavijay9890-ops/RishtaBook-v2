import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../services/moderation_service.dart';
import '../../services/astrologer_service.dart';
import '../../services/manual_topup_service.dart';
import '../../theme/app_colors.dart';
import '../../i18n/strings.dart';

const Color kBrandColor = AppColors.saffron;

/// Only reachable by emails listed in [AppConfig.adminEmails] (see the
/// admin icon in the dashboard AppBar). Tabs: pending verification
/// requests to approve/reject, a full export-able list of every user,
/// open safety reports, astrologer consultation requests, and app config.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("व्यवस्थापक डैशबोर्ड"),
          backgroundColor: kBrandColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(text: "सत्यापन / Verifications"),
              const Tab(text: "सभी उपयोगकर्ता / All Users"),
              Tab(text: context.t('admin.reportsTab')),
              Tab(text: context.t('admin.astrologerTab')),
              const Tab(text: "UPI टॉप-अप / UPI Top-ups"),
              const Tab(text: "सेटिंग्स / Settings"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _VerificationsTab(),
            _AllUsersTab(),
            _ReportsTab(),
            _AstrologerRequestsTab(),
            _ManualTopupsTab(),
            _SettingsTab(),
          ],
        ),
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();
  @override
  Widget build(BuildContext context) {
    final moderationService = ModerationService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: moderationService.openReportsStream(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Text(context.t('admin.noOpenReports')));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(context.t('safety.reason.${_reasonKey(data['reason'])}')),
                subtitle: Text('${data['details'] ?? ''}\nreporter: ${data['reporterUid']} · reported: ${data['reportedUid']}'),
                isThreeLine: true,
                trailing: TextButton(
                  onPressed: () => moderationService.resolveReport(doc.id),
                  child: Text(context.t('admin.resolve')),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _reasonKey(dynamic reason) {
    switch (reason) {
      case 'fake_profile': return 'fakeProfile';
      case 'inappropriate': return 'inappropriate';
      case 'harassment': return 'harassment';
      default: return 'other';
    }
  }
}

class _AstrologerRequestsTab extends StatelessWidget {
  const _AstrologerRequestsTab();
  @override
  Widget build(BuildContext context) {
    final astrologerService = AstrologerService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: astrologerService.pendingRequestsStream(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Text(context.t('admin.noAstrologerRequests')));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('${data['name']} · ${data['phone']}'),
                subtitle: Text('${context.t('astrologer.timeHint')}: ${data['preferredTime']}\n${data['notes'] ?? ''}'),
                isThreeLine: true,
                trailing: TextButton(
                  onPressed: () => astrologerService.markContacted(doc.id),
                  child: Text(context.t('admin.markContacted')),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Pending manual UPI top-up requests - see ManualTopupService's class doc.
/// Approving is the ONLY thing that actually grants credits for these;
/// rejecting just marks the request closed without touching the balance.
class _ManualTopupsTab extends StatefulWidget {
  const _ManualTopupsTab();
  @override
  State<_ManualTopupsTab> createState() => _ManualTopupsTabState();
}

class _ManualTopupsTabState extends State<_ManualTopupsTab> {
  final _service = ManualTopupService();
  final Set<String> _busy = {};

  Future<void> _approve(String requestId, String uid, int credits, int amountRupees) async {
    setState(() => _busy.add(requestId));
    try {
      await _service.approve(requestId, uid: uid, credits: credits, amountRupees: amountRupees);
    } finally {
      if (mounted) setState(() => _busy.remove(requestId));
    }
  }

  Future<void> _reject(String requestId) async {
    setState(() => _busy.add(requestId));
    try {
      await _service.reject(requestId);
    } finally {
      if (mounted) setState(() => _busy.remove(requestId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.pendingRequestsStream(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("कोई लंबित टॉप-अप नहीं। / No pending top-ups.", style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            final uid = data['uid'] as String? ?? '';
            final amountRupees = (data['amountRupees'] as num?)?.toInt() ?? 0;
            final credits = (data['credits'] as num?)?.toInt() ?? 0;
            final utr = data['utr'] as String? ?? '';
            final busy = _busy.contains(doc.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹$amountRupees → $credits credits', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('UTR: $utr', style: const TextStyle(fontSize: 13)),
                    Text('uid: $uid', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text("अस्वीकार करें", style: TextStyle(color: Colors.red)),
                          onPressed: busy ? null : () => _reject(doc.id),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: busy
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check, color: Colors.white),
                          label: const Text("स्वीकार करें", style: TextStyle(color: Colors.white)),
                          onPressed: busy ? null : () => _approve(doc.id, uid, credits, amountRupees),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Admin-tunable app config (`config/app` in Firestore) — currently just
/// the referral credit bonus, read by CreditService.getReferralBonusAmount
/// and mirrored by the matching firestore.rules check so client and rule
/// always agree on the live value.
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(int current) async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("सही संख्या डालें / Enter a valid number"), backgroundColor: Colors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('config').doc('app').set({'referralBonus': value}, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("सहेजा गया / Saved"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("त्रुटि / Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('config').doc('app').snapshots(),
      builder: (context, snap) {
        final current = (snap.data?.data()?['referralBonus'] as num?)?.toInt() ?? 50;
        if (_controller.text.isEmpty) _controller.text = '$current';
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("रेफ़रल क्रेडिट बोनस / Referral credit bonus",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Text("हर सफल रेफ़रल पर उपयोगकर्ता को मिलने वाले क्रेडिट। अभी: $current",
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Credits"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saving ? null : () => _save(current),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("सहेजें / Save"),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VerificationsTab extends StatelessWidget {
  const _VerificationsTab();

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: profileService.pendingVerificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBrandColor));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("कोई लंबित सत्यापन नहीं। / No pending verifications.",
                  style: TextStyle(color: Colors.grey)));
        }

        final profiles =
            snapshot.data!.docs.map((doc) => UserProfile.fromMap(doc.id, doc.data())).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("${profile.dob} • ${profile.gender} • ${profile.religion}",
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    Text("मोबाइल: ${profile.mobile}", style: const TextStyle(fontSize: 13)),
                    Text("स्थान: ${profile.location}", style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text("अस्वीकार करें", style: TextStyle(color: Colors.red)),
                            onPressed: () =>
                                profileService.setVerificationDecision(profile.uid, false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text("स्वीकार करें", style: TextStyle(color: Colors.white)),
                            onPressed: () =>
                                profileService.setVerificationDecision(profile.uid, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AllUsersTab extends StatefulWidget {
  const _AllUsersTab();

  @override
  State<_AllUsersTab> createState() => _AllUsersTabState();
}

class _AllUsersTabState extends State<_AllUsersTab> {
  bool _exporting = false;

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> _exportCsv(List<UserProfile> profiles) async {
    setState(() => _exporting = true);
    try {
      final headers = [
        "Full Name", "Date of Birth", "लिंग", "मोबाइल / Mobile", "Email", "धर्म / Religion", "वर्ग / Category",
        "Village", "District", "State", "व्यवसाय / Occupation", "परिवार की जानकारी", "Requirements",
        "सत्यापित / Verified", "सत्यापन स्थिति / Verification Status",
      ];
      final rows = <String>[headers.map(_csvEscape).join(",")];
      for (final p in profiles) {
        rows.add([
          p.fullName, p.dob, p.gender, p.mobile, p.email, p.religion, p.category,
          p.village, p.district, p.state, p.occupation, p.familyDetails, p.requirements,
          p.isVerified ? "हाँ" : "नहीं", p.verificationStatus,
        ].map(_csvEscape).join(","));
      }
      final csvContent = rows.join("\r\n");

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/rishtabook_users_$timestamp.csv');
      await file.writeAsString(csvContent);

      await Share.shareXFiles([XFile(file.path)],
          text: "RishtaBook - all users export (${profiles.length} users)");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("निर्यात में त्रुटि: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: profileService.allProfilesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBrandColor));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("कोई उपयोगकर्ता नहीं। / No users found.", style: TextStyle(color: Colors.grey)));
        }

        final profiles =
            snapshot.data!.docs.map((doc) => UserProfile.fromMap(doc.id, doc.data())).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _exporting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.download, color: Colors.white),
                  label: Text(_exporting ? "निर्यात हो रहा है... / Exporting..." : "Export सभी उपयोगकर्ता (CSV) - ${profiles.length} users",
                      style: const TextStyle(color: Colors.white)),
                  onPressed: _exporting ? null : () => _exportCsv(profiles),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final p = profiles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: kBrandColor.withOpacity(0.1),
                        child: Text(p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : "?",
                            style: const TextStyle(color: kBrandColor, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(p.email, style: const TextStyle(fontSize: 12)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailRow("जन्म तिथि / DOB", p.dob),
                              _detailRow("लिंग", p.gender),
                              _detailRow("मोबाइल / Mobile", p.mobile),
                              _detailRow("धर्म / Religion", p.religion),
                              _detailRow("वर्ग / Category", p.category),
                              _detailRow("पता / Location", p.location),
                              _detailRow("व्यवसाय / Occupation", p.occupation),
                              _detailRow("परिवार की जानकारी", p.familyDetails),
                              _detailRow("अपेक्षाएँ / Requirements", p.requirements),
                              _detailRow("सत्यापित / Verified", p.isVerified ? "हाँ" : "नहीं"),
                              _detailRow("सत्यापन स्थिति / Verification Status", p.verificationStatus),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12.5))),
          Expanded(child: Text(value.isEmpty ? "उपलब्ध नहीं" : value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
