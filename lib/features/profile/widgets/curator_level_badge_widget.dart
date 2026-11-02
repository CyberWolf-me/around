import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/curator_progression_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Interactive Curator Level Badge & XP Progress Bar Widget (`P23-02`).
/// Renders the curator's current tier badge, total XP, animated progress bar,
/// and remaining points to the next prestigious tier.
class CuratorLevelBadgeWidget extends StatelessWidget {
  final CuratorProgression? customProgression;
  final int dropsCount;
  final int streakWeeks;
  final int districtCrowns;
  final String languageCode;
  final VoidCallback? onTap;

  const CuratorLevelBadgeWidget({
    super.key,
    this.customProgression,
    this.dropsCount = 0,
    this.streakWeeks = 0,
    this.districtCrowns = 0,
    this.languageCode = 'en',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progression = customProgression ??
        CuratorProgressionEngine.calculate(
          dropsCount: dropsCount,
          streakWeeks: streakWeeks,
          districtCrowns: districtCrowns,
        );

    final tierColor = Color(progression.tier.badgeColorHex);

    return InkWell(
      key: const Key('curator_level_badge_card'),
      onTap: () {
        HapticService.selection();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: tierColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: const [AppColors.shadowCard],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Emoji Avatar, Level & Title, XP Chip
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    progression.tier.badgeEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              progression.localizedTitle(languageCode),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LVL ${progression.level}',
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tierColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progression.formattedProgressLabel(languageCode),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.ink3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Text(
                    '${progression.totalXp} XP',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress Bar Track
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    color: AppColors.paper3,
                  ),
                  FractionallySizedBox(
                    widthFactor: progression.progressFraction,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: tierColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Metrics Subtext Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progression.dropsCount} drops • ${progression.streakWeeks}w streak'
                  '${progression.districtCrowns > 0 ? " • 👑 ${progression.districtCrowns}" : ""}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.inkLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(progression.progressFraction * 100).round()}%',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: AppColors.ink2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
