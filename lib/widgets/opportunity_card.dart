import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/opportunity.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';
import 'type_chip.dart';

class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final VoidCallback onTap;
  final bool isFeatured;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = opportunity.timeAgo;

    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TypeChip(type: opportunity.type),
              Text(
                timeAgo,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            opportunity.displayTitle,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DELTA',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondarySolid,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${opportunity.deltaPoints.toStringAsFixed(1)} pts',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.accentGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Text(
                  opportunity.category.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondarySolid,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isFeatured) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            hasGlow: true,
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: content,
        ),
      ),
    );
  }
}
