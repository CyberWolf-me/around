import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/curator_recommendation_engine.dart';

class CuratorTasteOverlapCard extends StatelessWidget {
  final TasteOverlapMatch match;
  final String languageCode;
  final VoidCallback? onTap;

  const CuratorTasteOverlapCard({
    super.key,
    required this.match,
    this.languageCode = 'en',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = match.compatibilityPercent;
    final isHigh = percent >= 60;
    final isMedium = percent >= 30 && percent < 60;

    Color badgeBg;
    Color badgeFg;
    String badgeEmoji;

    if (isHigh) {
      badgeBg = AppColors.mintSubtle;
      badgeFg = AppColors.mint;
      badgeEmoji = '🔥';
    } else if (isMedium) {
      badgeBg = AppColors.butterSubtle;
      badgeFg = AppColors.orange;
      badgeEmoji = '✨';
    } else {
      badgeBg = AppColors.paper2;
      badgeFg = AppColors.ink3;
      badgeEmoji = '🌱';
    }

    final localizedHighlight = match.getLocalizedHighlight(languageCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHigh ? AppColors.mint.withValues(alpha: 0.35) : AppColors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(badgeEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'TASTE COMPATIBILITY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$percent% MATCH',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            localizedHighlight,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          // Shared tags or places chips
          if (match.sharedPlaces.isNotEmpty || match.sharedTags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...match.sharedPlaces.take(3).map((placeId) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place_outlined, size: 12, color: AppColors.orange),
                        const SizedBox(width: 4),
                        Text(
                          placeId,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                ...match.sharedTags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 11,
                        color: AppColors.ink2,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.explore_outlined, size: 14, color: AppColors.ink3),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Explore their profile to discover new neighborhood spots you haven\'t tried.',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(height: 12),
            InkWell(
              key: const Key('btn_curator_coffee_ping'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('☕', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      'Meet for Coffee',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.orange),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
