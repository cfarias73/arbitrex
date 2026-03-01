import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class FreemiumGate extends StatelessWidget {
  final Widget child;
  final bool isLocked;

  const FreemiumGate({
    super.key,
    required this.child,
    this.isLocked = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: AppColors.voidBg.withValues(alpha: 0.4),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.lock_fill, color: Colors.white, size: 24),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.purpleCore,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PRO',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
