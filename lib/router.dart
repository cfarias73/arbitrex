import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/recover_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/feed_screen.dart';
import 'screens/home/detail_screen.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/paywall_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/scaffold_with_navbar.dart';

final _supabase = Supabase.instance.client;

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = _supabase.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/recover' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/splash';

      if (!isAuthenticated && !isAuthRoute) return '/splash';
      if (isAuthenticated && (state.matchedLocation == '/' || state.matchedLocation == '/onboarding' || state.matchedLocation == '/splash')) return '/home';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(
      _supabase.auth.onAuthStateChange,
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/recover', builder: (_, __) => const RecoverScreen()),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
          GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/home/detail/:id',
        builder: (_, state) => DetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const PaywallScreen(),
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
