import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_layout.dart';
import 'bottom_navbar.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    int index = 0;
    if (location.startsWith('/home') || location.startsWith('/feed')) index = 0;
    if (location.startsWith('/alerts')) index = 1;
    if (location.startsWith('/stats')) index = 2;
    if (location.startsWith('/profile')) index = 3;

    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.voidBg,
        body: Row(
          children: [
            _buildSideRail(context, index),
            const VerticalDivider(thickness: 1, width: 1, color: AppColors.borderColor),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.voidBg,
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: index,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }

  void _onTap(BuildContext context, int i) {
    if (i == 0) context.go('/home');
    if (i == 1) context.go('/alerts');
    if (i == 2) context.go('/stats');
    if (i == 3) context.go('/profile');
  }

  Widget _buildSideRail(BuildContext context, int index) {
    return NavigationRail(
      selectedIndex: index,
      onDestinationSelected: (i) => _onTap(context, i),
      backgroundColor: AppColors.cardBg,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: AppColors.foxOrange),
      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
      selectedLabelTextStyle: const TextStyle(color: AppColors.foxOrange, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Image.asset('assets/images/Logos.png', height: 40),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(CupertinoIcons.house),
          selectedIcon: Icon(CupertinoIcons.house_fill),
          label: Text('Home'),
        ),
         NavigationRailDestination(
          icon: Icon(CupertinoIcons.bell),
          selectedIcon: Icon(CupertinoIcons.bell_fill),
          label: Text('Alerts'),
        ),
        NavigationRailDestination(
          icon: Icon(CupertinoIcons.graph_square),
          selectedIcon: Icon(CupertinoIcons.graph_square_fill),
          label: Text('Stats'),
        ),
        NavigationRailDestination(
          icon: Icon(CupertinoIcons.person),
          selectedIcon: Icon(CupertinoIcons.person_fill),
          label: Text('Profile'),
        ),
      ],
    );
  }
}
