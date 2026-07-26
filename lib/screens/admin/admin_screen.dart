import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

import '../../theme/app_theme.dart';

const Color kBrandColor = AppColors.primary;

/// Only reachable by emails listed in [AppConfig.adminEmails] (see the
/// admin icon in the dashboard AppBar). Lists every profile with
/// verificationStatus == 'pending' and lets the admin approve/reject.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Verifications"),
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: profileService.pendingVerificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kBrandColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("Koi pending verification request nahi hai.", style: TextStyle(color: Colors.grey)));
          }

          final profiles = snapshot.data!.docs
              .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
              .toList();

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
                      Text("Mobile: ${profile.mobile}", style: const TextStyle(fontSize: 13)),
                      Text("Location: ${profile.location}", style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text("Reject", style: TextStyle(color: Colors.red)),
                              onPressed: () =>
                                  profileService.setVerificationDecision(profile.uid, false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text("Approve", style: TextStyle(color: Colors.white)),
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
      ),
    );
  }
}
