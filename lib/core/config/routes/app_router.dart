import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../presentation/screens/login_page.dart';
import '../../../presentation/screens/dashboard_page.dart';
import '../../../presentation/screens/profile_page.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);