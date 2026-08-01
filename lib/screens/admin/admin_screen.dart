import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

const Color kBrandColor = AppColors.primary;

/// Only reachable by emails listed in [AppConfig.adminEmails] (see the
/// admin icon in the dashboard AppBar). Two tabs: pending verification
/// requests to approve/reject, and a full export-able list of every user.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("व्यवस्थापक डैशबोर्ड"),
          backgroundColor: kBrandColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "सत्यापन / Verifications"),
              Tab(text: "सभी उपयोगकर्ता / All Users"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _VerificationsTab(),
            _AllUsersTab(),
          ],
        ),
      ),
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
                        child: Text(p.fullName.isEmpty ? p.fullName[0].toUpperCase() : "?",
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
