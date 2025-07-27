import 'package:fam_bite/screens/signup_screen.dart';
import 'package:fam_bite/screens/splash_screen.dart';
import 'package:fam_bite/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/parent_screen.dart';
import 'screens/child_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FamBiteApp());
}

class FamBiteApp extends StatelessWidget {
  const FamBiteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamBite',
      theme: appTheme(),
      routes: {
        '/splash': (c) => const SplashScreen(),
        '/': (c) => const AuthWrapper(),
        '/login': (c) => const LoginScreen(),
        '/signup': (c) => const SignUpScreen(),
        '/register': (c) => const RegistrationScreen(),
        '/subscribe': (c) => const SubscriptionScreen(),
        '/parent': (c) => const ParentScreen(),
        '/child': (c) => const ChildScreen(),
      },
      initialRoute: '/splash',
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState != ConnectionState.active) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) return const LoginScreen();

        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('users/${user.uid}').onValue,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.active) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snap.data?.snapshot.value;
            if (data == null) return const RegistrationScreen();

            final userMap = Map<String, dynamic>.from(data as Map);
            final subscribed = userMap['subscription']?['active'] == true;
            final role = userMap['role'] as String? ?? 'child';

            if (!subscribed) return const SubscriptionScreen();
            return role == 'parent'
                ? const ParentScreen()
                : const ChildScreen();
          },
        );
      },
    );
  }
}
