import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RishtaBook',
      theme: AppTheme.light,
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          if (snapshot.hasData) {
            // Check if profile is complete (has fullName and gender filled)
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, profileSnap) {
                if (profileSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }
                final data = profileSnap.data?.data();
                final bool profileComplete =
                    data != null &&
                    (data['fullName'] ?? '').toString().trim().isNotEmpty &&
                    (data['gender'] ?? '').toString().trim().isNotEmpty &&
                    (data['religion'] ?? '').toString().trim().isNotEmpty;

                if (profileComplete) {
                  return const DashboardScreen();
                }
                // Profile incomplete — send to signup screen
                return const LoginScreen();
              },
            );
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
