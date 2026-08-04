import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'theme/app_theme.dart';
import 'i18n/language_controller.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/root_shell.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/wallet/wallet_page.dart';
import 'screens/kundali/kundali_page.dart';
import 'screens/chat/chat_page.dart';
import 'screens/profile/view_profile_screen.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBlScDXJDv6P6kcR6c5FUyWxT_LAyucduE",
      appId: "1:838898779560:android:14edeacd3f6af2b853099d",
      messagingSenderId: "838898779560",
      projectId: "rishtabook-60663",
    ),
  );

  await MobileAds.instance.initialize();

  final languageController = LanguageController();
  await languageController.load();

  runApp(MultiProvider(
    providers: [ChangeNotifierProvider.value(value: languageController)],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RishtaBook',
      theme: AppTheme.light,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/root':
            return MaterialPageRoute(builder: (_) => const RootShell());
          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminScreen());
          case '/wallet':
            return MaterialPageRoute(builder: (_) => const WalletPage());
          case '/kundali':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => KundaliPage(otherUid: args['otherUid'] as String, otherName: args['otherName'] as String),
            );
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ChatPage(
                matchId: args['matchId'] as String,
                otherUserName: args['otherUserName'] as String,
                currentUserId: args['currentUserId'] as String,
              ),
            );
          case '/view-profile':
            final profile = settings.arguments as UserProfile;
            return MaterialPageRoute(builder: (_) => ViewProfileScreen(profile: profile));
          default:
            return MaterialPageRoute(builder: (_) => const AuthGate());
        }
      },
    );
  }
}

/// Decides Login vs. the main app shell from live auth + profile state.
/// A user who is authenticated but whose profile is missing required
/// fields (e.g. a first Google sign-in, which only sets fullName/email)
/// is routed to the registration form in "complete your profile" mode
/// instead of being dropped back on a login form they can't use.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const _Loading();
            }
            final data = profileSnap.data?.data();
            final complete = data != null &&
                (data['fullName'] ?? '').toString().trim().isNotEmpty &&
                (data['gender'] ?? '').toString().trim().isNotEmpty &&
                (data['religion'] ?? '').toString().trim().isNotEmpty;

            if (complete) return const RootShell();
            return LoginScreen(completingProfileFor: user);
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
