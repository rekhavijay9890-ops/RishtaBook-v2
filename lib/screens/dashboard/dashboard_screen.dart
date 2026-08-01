import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/interest_service.dart';
import '../../services/chat_service.dart';
import '../admin/admin_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/interests_tab.dart';
import 'tabs/chats_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/about_tab.dart';
import '../../theme/app_theme.dart';

const Color kBrandColor = AppColors.primary;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final InterestService _interestService = InterestService();
  final ChatService _chatService = ChatService();

  final List<Widget> _pages = const [
    HomeTab(),
    InterestsTab(),
    ChatsTab(),
    ProfileTab(),
    AboutTab(),
  ];

  void _showNotifications(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notifications"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _interestService.receivedInterestsStream(uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: kBrandColor));
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("कोई नई सूचना नहीं है। / No new notifications."));
              }
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data();
                  final name = data['fromName'] ?? 'Kisi ne';
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: kBrandColor,
                      child: Icon(Icons.favorite, color: Colors.white, size: 18),
                    ),
                    title: Text("$name ने आपको रुचि भेजी है"),
                    subtitle: const Text("रुचि टैब में जाकर / Go to Interests tab to accept/decline"),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 1);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("बंद करें / Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final uid = currentUser?.uid ?? "";
    final isAdmin = AppConfig.isAdmin(currentUser?.email);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _interestService.receivedInterestsStream(uid),
      builder: (context, notifSnapshot) {
        final pendingCount = notifSnapshot.data?.docs.length ?? 0;

        return StreamBuilder<int>(
          stream: _chatService.totalUnreadStream(uid),
          builder: (context, chatSnapshot) {
            final unreadChats = chatSnapshot.data ?? 0;

        return Scaffold(
          backgroundColor: AppColors.background,
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
                  tooltip: "एडमिन / Admin: लंबित सत्यापन / Pending Verifications",
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const AdminScreen())),
                ),
              Badge(
                label: Text('$pendingCount'),
                isLabelVisible: pendingCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.notifications_active),
                  onPressed: () => _showNotifications(uid),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: kBrandColor,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: "मुखपृष्ठ"),
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text('$pendingCount'),
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.favorite),
                ),
                label: "रुचियाँ / Interests",
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text('$unreadChats'),
                  isLabelVisible: unreadChats > 0,
                  child: const Icon(Icons.chat),
                ),
                label: "बातचीत / Chats",
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: "प्रोफ़ाइल / Profile"),
              const BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: "जानकारी"),
            ],
          ),
        );
      },
    );
  },
);
  }
}
