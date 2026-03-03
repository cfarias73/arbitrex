import 'package:flutter/material.dart';

class AppColors {
  static const voidBg = Color(0xFF07050F);
  static const surface = Color(0xFF150F2E);
  static const cardBg = Color(0xFF1C1540);
  static const borderColor = Color(0xFF2E2460);
  static const foxOrange = Color(0xFFFF4D00); // Eléctrico y vibrante
  static const foxOrangeBright = Color(0xFFFF8533);
  static const foxOrangeGlow = Color(0xFFFFB280);
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
    colors: [foxOrange, Color(0xFFE64500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
