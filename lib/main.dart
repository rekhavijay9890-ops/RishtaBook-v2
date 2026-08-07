import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'config/app_config.dart';
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

  // No screen in this app (bottom nav, forms, headers) is laid out
  // responsively for landscape - e.g. the sign-in screen uses Spacers
  // sized for portrait height and overflows once the viewport shrinks in
  // landscape. Lock to portrait rather than chase every screen's overflow
  // individually.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Most screens (the 5 root tabs especially) use a plain Container header
  // instead of a real AppBar, so AppTheme's appBarTheme.systemOverlayStyle
  // never applies to them - set the OS's own on-screen nav bar colour here
  // instead so it always matches the app's white bottomNavigationBar and
  // never looks like it's clashing with/overlapping the tab bar above it.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: AppColors.cardBg,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: AppColors.borderColor,
  ));

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBlScDXJDv6P6kcR6c5FUyWxT_LAyucduE",
      appId: "1:838898779560:android:14edeacd3f6af2b853099d",
      messagingSenderId: "838898779560",
      projectId: "rishtabook-60663",
      storageBucket: "rishtabook-60663.firebasestorage.app",
    ),
  );

  // Storage-only: profile photos live in Supabase Storage (see AppConfig
  // doc), everything else (auth, all app data) stays on Firebase/Firestore.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Not awaited: this is a network call to Google's ad SDK. It only needs
  // to finish before the Wallet tab's "Watch ad" button loads a
  // RewardedAd - by then the user has navigated at least one screen away
  // from boot, so it's always ready in practice. Awaiting it here blocked
  // the whole app from rendering until it finished - the single biggest
  // contributor to a slow cold boot.
  MobileAds.instance.initialize();

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
      // Several screens' text styles (see AppText) sit as low as 9-13px,
      // which reads as too small on real devices - especially since this
      // app skews toward an older user base. Floor everyone at 1.15x
      // regardless of the OS setting, while still letting a user's own
      // "larger text" accessibility setting scale further (capped so
      // layouts don't break at extreme system scales).
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final scaler = mq.textScaler.clamp(minScaleFactor: 1.15, maxScaleFactor: 1.4);
        return MediaQuery(data: mq.copyWith(textScaler: scaler), child: child!);
      },
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
