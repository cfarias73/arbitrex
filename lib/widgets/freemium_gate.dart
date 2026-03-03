import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class FreemiumGate extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final double? delta;

  const FreemiumGate({
    super.key,
    required this.child,
    this.isLocked = true,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.voidBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (delta != null) ...[
                        Text(
                          '+${delta!.toStringAsFixed(1)} pts',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.accentGreen,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: AppColors.accentGreen.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Icon(CupertinoIcons.lock_fill, color: Colors.white, size: 28),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => context.push('/paywall'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.foxOrange,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.foxOrange.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'UNLOCK PRO',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
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
