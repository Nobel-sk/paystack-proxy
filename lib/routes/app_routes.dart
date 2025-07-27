import 'package:go_router/go_router.dart';

import 'package:fam_bite/screens/login_screen.dart';
import 'package:fam_bite/screens/signup_screen.dart';
import 'package:fam_bite/screens/registration_screen.dart';
import 'package:fam_bite/screens/subscription_screen.dart';
import 'package:fam_bite/screens/child_screen.dart';
import 'package:fam_bite/screens/parent_screen.dart';
import 'package:fam_bite/screens/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/subscription',
      name: 'subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/child',
      name: 'child',
      builder: (context, state) => const ChildScreen(),
    ),
    GoRoute(
      path: '/parent',
      name: 'parent',
      builder: (context, state) => const ParentScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/subscribe',
      builder: (context, state) => const SubscriptionScreen(),
    ),
  ],
);
