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
    if (location.startsWith('/home') || location.startsWith('/feed')) index = 0;
    if (location.startsWith('/stats')) index = 1;
    if (location.startsWith('/profile')) index = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: index,
        onTap: (i) {
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/stats');
          if (i == 2) context.go('/profile');
        },
      ),
    );
  }
}
