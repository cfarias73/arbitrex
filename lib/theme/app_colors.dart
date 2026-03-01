import 'package:flutter/material.dart';

class AppColors {
  static const voidBg = Color(0xFF07050F);
  static const surface = Color(0xFF150F2E);
  static const cardBg = Color(0xFF1C1540);
  static const borderColor = Color(0xFF2E2460);
  static const purpleCore = Color(0xFF8B5CF6);
  static const purpleBright = Color(0xFFA78BFA);
  static const purpleGlow = Color(0xFFC4B5FD);
  static const accentCyan = Color(0xFF22D3EE);
  static const accentGreen = Color(0xFF34D399);
  static const accentRed = Color(0xFFF87171);
  static const accentAmber = Color(0xFFFBBF24);
  static const textPrimary = Color(0xFFF0EEFF);
  static const textSecondary = Color(0xA89EC9FF); // Corrected from 0xFFA89EC9 to include alpha if needed, but original was 0xFFA89EC9. Let's stick to PRD.
  static const textSecondarySolid = Color(0xFFA89EC9);
  static const textMuted = Color(0xFF5E5380);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [purpleCore, Color(0xFF7C3AED)], // purple_core -> purple_mid (approximated purple_mid as 7C3AED)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
