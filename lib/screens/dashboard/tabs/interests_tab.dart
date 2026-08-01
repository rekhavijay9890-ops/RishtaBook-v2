import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/interest.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/interest_service.dart';
import '../../../services/profile_service.dart';
import '../../profile/view_profile_screen.dart';
import '../../../theme/app_theme.dart';

const Color kBrandColor = AppColors.primary;

class InterestsTab extends StatelessWidget {
  const InterestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: kBrandColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kBrandColor,
              tabs: [
                Tab(text: "प्राप्त / Received"),
                Tab(text: "भेजी गई / Sent"),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _प्राप्तInterests(),
                _भेजी गईInterests(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _प्राप्तInterests extends StatelessWidget {
  const _प्राप्तInterests();

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final interestService = InterestService();
    final uid = authService.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: interestService.receivedInterestsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBrandColor));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("अभी तक कोई रुचि नहीं आई।", style: TextStyle(color: Colors.grey)));
        }

        final interests = snapshot.data!.docs.map((doc) => Interest.fromDoc(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: interests.length,
          itemBuilder: (context, index) {
            final interest = interests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () async {
                        final doc = await ProfileService().getUserProfile(interest.fromUid);
                        if (!context.mounted) return;
                        if (!doc.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text("प्रोफ़ाइल लोड नहीं हो पाई। / Profile could not be loaded.")));
                          return;
                        }
                        final profile = UserProfile.fromMap(doc.id, doc.data()!);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => ViewProfileScreen(profile: profile)));
                      },
                      child: Row(
                        children: [
                          const CircleAvatar(
                              backgroundColor: Colors.pink,
                              child: Icon(Icons.favorite, color: Colors.white)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text("${interest.fromName} ने आपको रुचि भेजी है / sent you an interest",
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text("अस्वीकार करें"),
                            onPressed: () => interestService.respondToInterest(
                              interestId: interest.id,
                              fromUid: interest.fromUid,
                              toUid: interest.toUid,
                              accept: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            icon: const Icon(Icons.check, size: 18, color: Colors.white),
                            label: const Text("स्वीकार करें", style: TextStyle(color: Colors.white)),
                            onPressed: () => interestService.respondToInterest(
                              interestId: interest.id,
                              fromUid: interest.fromUid,
                              toUid: interest.toUid,
                              accept: true,
                            ),
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

class _भेजी गईInterests extends StatelessWidget {
  const _भेजी गईInterests();

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final interestService = InterestService();
    final uid = authService.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: interestService.sentInterestsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBrandColor));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("आपने अभी तक कोई रुचि नहीं भेजी।", style: TextStyle(color: Colors.grey)));
        }

        final interests = snapshot.data!.docs.map((doc) => Interest.fromDoc(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: interests.length,
          itemBuilder: (context, index) {
            final interest = interests[index];
            Color statusColor = Colors.orange;
            String statusText = "प्रतीक्षित";
            if (interest.status == 'accepted') {
              statusColor = Colors.green;
              statusText = "स्वीकार करेंed - Chat mein jaayein!";
            } else if (interest.status == 'rejected') {
              statusColor = Colors.red;
              statusText = "अस्वीकार करेंd";
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: kBrandColor, child: Icon(Icons.send, color: Colors.white)),
                title: Text(interest.toName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
              ),
            );
          },
        );
      },
    );
  }
}
