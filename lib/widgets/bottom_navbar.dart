import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.purpleBright,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bolt_fill, size: 20),
            label: 'FEED',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.compass, size: 20),
            label: 'EXPLORE',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bell_fill, size: 20),
            label: 'ALERTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_fill, size: 20),
            label: 'STATS',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_fill, size: 20),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}
