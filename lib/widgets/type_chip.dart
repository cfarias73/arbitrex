import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class TypeChip extends StatelessWidget {
  final String type;

  const TypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (type) {
      case 'type_a':
        color = AppColors.foxOrangeBright;
        label = 'INTRA';
        break;
      case 'type_b':
        color = AppColors.accentCyan;
        label = 'INTER';
        break;
      case 'type_c':
        color = AppColors.accentAmber;
        label = 'ANOMALY';
        break;
      default:
        color = AppColors.textMuted;
        label = 'OTHER';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
