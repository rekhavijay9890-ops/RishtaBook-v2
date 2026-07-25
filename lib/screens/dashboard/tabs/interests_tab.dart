import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/interest.dart';
import '../../../services/auth_service.dart';
import '../../../services/interest_service.dart';

const Color kBrandColor = Color(0xFF0F766E);

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
                Tab(text: "Received"),
                Tab(text: "Sent"),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ReceivedInterests(),
                _SentInterests(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedInterests extends StatelessWidget {
  const _ReceivedInterests();

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
              child: Text("Abhi tak koi interest nahi aaya hai.", style: TextStyle(color: Colors.grey)));
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
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Colors.pink, child: Icon(Icons.favorite, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text("${interest.fromName} ne aapko interest bheja hai",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                      onPressed: () => interestService.respondToInterest(
                        interestId: interest.id,
                        fromUid: interest.fromUid,
                        toUid: interest.toUid,
                        accept: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                      onPressed: () => interestService.respondToInterest(
                        interestId: interest.id,
                        fromUid: interest.fromUid,
                        toUid: interest.toUid,
                        accept: false,
                      ),
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

class _SentInterests extends StatelessWidget {
  const _SentInterests();

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
              child: Text("Aapne abhi tak koi interest nahi bheja hai.", style: TextStyle(color: Colors.grey)));
        }

        final interests = snapshot.data!.docs.map((doc) => Interest.fromDoc(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: interests.length,
          itemBuilder: (context, index) {
            final interest = interests[index];
            Color statusColor = Colors.orange;
            String statusText = "Pending";
            if (interest.status == 'accepted') {
              statusColor = Colors.green;
              statusText = "Accepted - Chat mein jaayein!";
            } else if (interest.status == 'rejected') {
              statusColor = Colors.red;
              statusText = "Declined";
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
