import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/interest_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import 'home/home_page.dart';
import 'search/search_page.dart';
import 'interests/interests_page.dart';
import 'chat/chats_list_page.dart';
import 'profile/profile_page.dart';
import 'notifications/notifications_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final InterestService _interestService = InterestService();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    final uid = AuthService().currentUser?.uid;
    if (uid != null) PushService().registerToken(uid);
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _interestService.receivedInterestsStream(uid),
      builder: (context, notifSnap) {
        final pendingCount = notifSnap.data?.docs.length ?? 0;
        return StreamBuilder<int>(
          stream: _chatService.totalUnreadStream(uid),
          builder: (context, chatSnap) {
            final unread = chatSnap.data ?? 0;
            return Scaffold(
              extendBody: true,
              body: IndexedStack(
                index: _index,
                children: const [
                  HomePage(),
                  SearchPage(),
                  InterestsPage(),
                  ChatsListPage(),
                  ProfilePage(),
                ],
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: AppColors.borderColor),
                    boxShadow: [
                      BoxShadow(color: AppColors.saffron.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BottomNavigationBar(
                      currentIndex: _index,
                      onTap: (i) => setState(() => _index = i),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: AppColors.saffron,
                      unselectedItemColor: AppColors.ghost,
                      items: [
                        const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                        const BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
                        BottomNavigationBarItem(
                          icon: Badge(label: Text('$pendingCount'), isLabelVisible: pendingCount > 0, child: const Icon(Icons.favorite_border_rounded)),
                          label: 'Interests',
                        ),
                        BottomNavigationBarItem(
                          icon: Badge(label: Text('$unread'), isLabelVisible: unread > 0, child: const Icon(Icons.chat_bubble_outline_rounded)),
                          label: 'Chat',
                        ),
                        const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class RootHeaderActions extends StatelessWidget {
  const RootHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final uid = auth.currentUser?.uid ?? '';
    final isAdmin = AppConfig.isAdmin(auth.currentUser?.email);
    final notificationService = NotificationService();

    return Row(
      children: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            tooltip: 'Admin',
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          ),
        StreamBuilder<int>(
          stream: notificationService.unreadCountStream(uid),
          builder: (context, snap) {
            final count = snap.data ?? 0;
            return IconButton(
              icon: Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            );
          },
        ),
      ],
    );
  }
}
