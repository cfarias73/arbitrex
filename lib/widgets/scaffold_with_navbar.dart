import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_navbar.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    int index = 0;
    if (location.startsWith('/home')) index = 0;
    if (location.startsWith('/explore')) index = 1; // Placeholder for Explore
    if (location.startsWith('/alerts')) index = 2;
    if (location.startsWith('/stats')) index = 3;
    if (location.startsWith('/profile')) index = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: index,
        onTap: (i) {
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/home'); // Explore currently points to Home
          if (i == 2) context.go('/alerts');
          if (i == 3) context.go('/stats');
          if (i == 4) context.go('/profile');
        },
      ),
    );
  }
}
