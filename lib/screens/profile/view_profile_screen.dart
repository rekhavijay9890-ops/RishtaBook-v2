import 'package:flutter/material.dart';

import '../../models/user_profile.dart';

const Color kBrandColor = Color(0xFF0F766E);

/// Read-only, full-detail view of a profile - every field the person
/// filled in at signup (not just the shortened preview shown on the
/// Home tab card).
class ViewProfileScreen extends StatelessWidget {
  final UserProfile profile;
  const ViewProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    IconData avatarIcon = Icons.person;
    Color avatarColor = Colors.grey;
    if (profile.isFemale) {
      avatarIcon = Icons.face_3;
      avatarColor = Colors.pink;
    } else if (profile.isMale) {
      avatarIcon = Icons.face;
      avatarColor = Colors.blue;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Details"),
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: avatarColor.withOpacity(0.12),
              child: Icon(avatarIcon, size: 50, color: avatarColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(profile.fullName,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: kBrandColor, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _Section(title: "Basic Details", children: [
            _Row(Icons.calendar_today, "Date of Birth", profile.dob),
            _Row(Icons.people, "Gender", profile.gender),
            _Row(Icons.menu_book, "Religion", profile.religion),
            _Row(Icons.groups, "Category", profile.category),
          ]),
          _Section(title: "Location", children: [
            _Row(Icons.home, "Address", profile.location),
          ]),
          _Section(title: "Occupation & Family", children: [
            _Row(Icons.work, "Occupation", profile.occupation),
            _Row(Icons.family_restroom, "Family Details", profile.familyDetails),
          ]),
          _Section(title: "Partner Requirement", children: [
            _Row(Icons.list_alt, "What they're looking for", profile.requirements),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: kBrandColor)),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: kBrandColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? "N/A" : value,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}