import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../admin/admin_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/interests_tab.dart';
import 'tabs/chats_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/about_tab.dart';

const Color kBrandColor = Color(0xFF0F766E);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final ProfileService _profileService = ProfileService();

  final List<Widget> _pages = const [
    HomeTab(),
    InterestsTab(),
    ChatsTab(),
    ProfileTab(),
    AboutTab(),
  ];

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Recent Activities"),
        content: SizedBox(
          width: double.maxFinite,
          height: 250,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _profileService.recentJoinsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Koi nayi activity nahi hai."));
              }
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data();
                  final name = data['fullName'] ?? 'Naya User';
                  final district = data['district'] ?? 'ek naye shahar';
                  return ListTile(
                    leading: const Icon(Icons.person_add, color: Colors.blue),
                    title: Text("$name ne app join kiya!"),
                    subtitle: Text("$district se hain."),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AppConfig.isAdmin(AuthService().currentUser?.email);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("RishtaBook", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: "Admin: pending verifications",
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const AdminScreen())),
            ),
          IconButton(icon: const Icon(Icons.notifications_active), onPressed: _showNotifications),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: kBrandColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Interests"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: "About"),
        ],
      ),
    );
  }
}
