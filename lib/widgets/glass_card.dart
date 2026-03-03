import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool hasGlow;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: AppColors.foxOrange.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0x991C1540), // rgba(28,21,64,0.6)
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.foxOrange.withValues(alpha: 0.25), // rgba(139,92,246,0.25)
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
