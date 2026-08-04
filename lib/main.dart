import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'theme/app_theme.dart';
import 'i18n/language_controller.dart';
import 'services/auth_service.dart';
import 'screens/auth/auth_landing_screen.dart';
import 'screens/auth/basic_details_screen.dart';
import 'screens/auth/profile_choice_screen.dart';
import 'screens/root_shell.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/wallet/wallet_page.dart';
import 'screens/kundali/kundali_page.dart';
import 'screens/chat/chat_page.dart';
import 'screens/profile/view_profile_screen.dart';
import 'screens/referral/referral_screen.dart';
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
          case '/referral':
            return MaterialPageRoute(builder: (_) => const ReferralScreen());
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

/// Decides Sign-in vs. Basic details vs. Complete-or-skip vs. the main app
/// shell from live auth + profile state — a StreamBuilder on the user doc
/// (not a one-shot get()) so every stage transitions automatically as soon
/// as the previous screen writes to Firestore, with no manual navigation
/// wired between them.
///
/// Stages, in order:
/// 1. Not signed in -> AuthLandingScreen (Google / Mobile OTP / email).
/// 2. Signed in but missing name/DOB/gender/mobile or never accepted the
///    disclaimer -> BasicDetailsScreen. This applies to brand-new sign-ups
///    AND to any pre-redesign account that predates consent capture, so
///    every user ends up having explicitly agreed to it - closing the gap
///    where Google sign-in used to skip it entirely.
/// 3. Basic details done, but never made the complete-vs-skip choice ->
///    ProfileChoiceScreen. Skipped automatically for legacy accounts that
///    clearly already filled in the old extended form (religion is set).
/// 4. Otherwise -> RootShell.
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
        if (user == null) return const AuthLandingScreen();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const _Loading();
            }
            final data = profileSnap.data?.data();

            final basicComplete = data != null &&
                (data['fullName'] ?? '').toString().trim().isNotEmpty &&
                (data['gender'] ?? '').toString().trim().isNotEmpty &&
                (data['age'] ?? '').toString().trim().isNotEmpty &&
                (data['mobile'] ?? '').toString().trim().isNotEmpty &&
                data['disclaimerAccepted'] == true;
            if (!basicComplete) return BasicDetailsScreen(user: user, existingData: data);

            final legacyComplete = (data['religion'] ?? '').toString().trim().isNotEmpty;
            final choiceMade = data['onboardingChoiceMade'] == true;
            if (!choiceMade && !legacyComplete) {
              return ProfileChoiceScreen(uid: user.uid, fullName: (data['fullName'] ?? '').toString());
            }

            return const RootShell();
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
