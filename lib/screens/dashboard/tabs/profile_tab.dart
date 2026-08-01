import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../auth/login_screen.dart';
import '../../../theme/app_theme.dart';

const Color kBrandColor = AppColors.primary;

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final profileService = ProfileService();
    final user = authService.currentUser;

    if (user == null) return const Center(child: Text("कृपया लॉगिन करें / Please login"));

    Future<void> logout() async {
      await authService.signOut();
      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileService.userProfileStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBrandColor));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("प्रोफ़ाइल डेटा नहीं मिला। / Profile data not found."),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: logout, child: const Text("लॉगआउट / Logout")),
              ],
            ),
          );
        }

        final profile = UserProfile.fromMap(user.uid, snapshot.data!.data()!);

        Widget verificationBox;
        if (profile.isVerified) {
          verificationBox = _StatusBanner(
            icon: Icons.verified,
            color: Colors.green,
            title: "प्रोफ़ाइल सत्यापित / Profile Verified",
            subtitle: "आपकी प्रोफ़ाइल व्यवस्थापक द्वारा सत्यापित हो चुकी है।",
          );
        } else if (profile.verificationStatus == 'pending') {
          verificationBox = _StatusBanner(
            icon: Icons.hourglass_top,
            color: Colors.orange,
            title: "Verification प्रतीक्षित",
            subtitle: "व्यवस्थापक जल्द ही आपकी प्रोफ़ाइल देखेंगे।",
          );
        } else if (profile.verificationStatus == 'rejected') {
          verificationBox = _StatusBanner(
            icon: Icons.error_outline,
            color: Colors.red,
            title: "सत्यापन अस्वीकृत / Verification Rejected",
            subtitle: "कृपया व्यवस्थापक से संपर्क करें।",
            action: TextButton(
              onPressed: () => profileService.requestVerification(user.uid),
              child: const Text("फिर से अनुरोध करें"),
            ),
          );
        } else {
          verificationBox = _StatusBanner(
            icon: Icons.shield_outlined,
            color: kBrandColor,
            title: "सत्यापित हों",
            subtitle: "सत्यापित बैज से आपकी प्रोफ़ाइल पर ज़्यादा विश्वास मिलता है।",
            action: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kBrandColor),
              onPressed: () => profileService.requestVerification(user.uid),
              child: const Text("सत्यापन अनुरोध करें", style: TextStyle(color: Colors.white)),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: kBrandColor,
                child: Text(
                  profile.fullName.isEmpty ? profile.fullName[0].toUpperCase() : "?",
                  style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(profile.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (profile.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: kBrandColor, size: 20),
                ],
              ],
            ),
            Center(child: Text(profile.email, style: const TextStyle(color: Colors.grey))),
            const SizedBox(height: 20),
            verificationBox,
            const SizedBox(height: 20),
            _InfoTile(icon: Icons.calendar_today, title: "जन्म तिथि / Date of Birth", value: profile.dob),
            _InfoTile(icon: Icons.people, title: "लिंग / Ling", value: profile.gender),
            _InfoTile(icon: Icons.menu_book, title: "धर्म / Dharm", value: profile.religion),
            _InfoTile(icon: Icons.groups, title: "वर्ग / Varg", value: profile.category),
            if (profile.caste.isEmpty)
              _InfoTile(icon: Icons.account_tree, title: "जाति / Caste", value: profile.caste),
            if (profile.gotra.isEmpty)
              _InfoTile(icon: Icons.spa, title: "Gotra", value: profile.gotra),
            _InfoTile(icon: Icons.work, title: "व्यवसाय / Kaam", value: profile.occupation),
            _InfoTile(icon: Icons.home, title: "पता / Address", value: profile.location),
            if (profile.brothers.isEmpty)
              _InfoTile(icon: Icons.person, title: "भाई", value: profile.brothers),
            if (profile.sisters.isEmpty)
              _InfoTile(icon: Icons.person, title: "बहन", value: profile.sisters),
            _InfoTile(icon: Icons.family_restroom, title: "परिवार की जानकारी", value: profile.familyDetails),
            _InfoTile(icon: Icons.list_alt, title: "जीवनसाथी की प्राथमिकता", value: profile.requirements),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("खाता लॉगआउट करें / Logout Account", style: TextStyle(color: Colors.white)),
                onPressed: logout,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? action;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                if (action != null) action!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: kBrandColor),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
