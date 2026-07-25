import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/interest_service.dart';
import '../../profile/view_profile_screen.dart';

const Color kBrandColor = Color(0xFF0F766E);

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final profileService = ProfileService();
    final currentUserId = authService.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: profileService.allProfilesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBrandColor));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Abhi tak koi naya profile nahi hai."));
        }

        final allProfiles =
            snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();

        if (allProfiles.isEmpty) {
          return const Center(
              child: Text("Abhi aapke alawa koi aur user nahi hai.",
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Recommended Matches",
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandColor)),
            const SizedBox(height: 15),
            ...allProfiles.map((doc) {
              final profile = UserProfile.fromMap(doc.id, doc.data());
              return _ProfileCard(currentUserId: currentUserId, profile: profile);
            }),
          ],
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
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final exists = await _interestService.hasExistingInterest(
        widget.currentUserId, widget.profile.uid);
    if (mounted) setState(() {
      _alreadySent = exists;
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
              content: Text("Interest pehle se bheja ja chuka hai.")));
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
            content: Text("${widget.profile.fullName} ko interest bhej diya gaya! 💌"),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Interest bhejne mein error aayi."), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() {
        _alreadySent = true;
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
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ViewProfileScreen(profile: profile))),
                      child: const Text("View Full Profile"),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _alreadySent ? Colors.grey.shade300 : kBrandColor,
                      ),
                      icon: Icon(_alreadySent ? Icons.check : Icons.favorite_border,
                          size: 18, color: _alreadySent ? Colors.grey.shade700 : Colors.white),
                      label: Text(
                        _checking
                            ? "..."
                            : (_alreadySent ? "Sent" : "Send Interest"),
                        style: TextStyle(color: _alreadySent ? Colors.grey.shade700 : Colors.white),
                      ),
                      onPressed: (_checking || _alreadySent) ? null : _sendInterest,
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