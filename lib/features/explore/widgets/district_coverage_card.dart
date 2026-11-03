import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/personal_coverage_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Interactive District Coverage Card & Exploration Overlay Widget (`P24-02`).
/// Visualizes the curator's personal exploration heat across Tashkent districts,
/// displays district completion percentages, and recommends the next unvisited gem.
class DistrictCoverageCard extends StatelessWidget {
  final CityCoverageReport? customReport;
  final Set<String> visitedPlaceIds;
  final String languageCode;
  final ValueChanged<String>? onSelectDistrict;
  final ValueChanged<String>? onTapRecommendation;

  const DistrictCoverageCard({
    super.key,
    this.customReport,
    this.visitedPlaceIds = const {},
    this.languageCode = 'en',
    this.onSelectDistrict,
    this.onTapRecommendation,
  });

  @override
  Widget build(BuildContext context) {
    final report = customReport ??
        PersonalCoverageEngine.calculateCoverage(
          visitedPlaceIds: visitedPlaceIds,
        );

    return Container(
      key: const Key('district_coverage_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.orangeSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Text('🗺️', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TASHKENT EXPLORATION HEAT',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink3,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.formattedCityScore(languageCode),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${report.overallPercentage}%',
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overall City Progress Track
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, width: double.infinity, color: AppColors.paper3),
                FractionallySizedBox(
                  widthFactor: report.overallFraction,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // District Breakdown Rows
          ...report.districts.values.map((district) {
            return InkWell(
              key: Key('district_row_${district.district.toLowerCase().replaceAll(' ', '_')}'),
              onTap: () {
                HapticService.selection();
                onSelectDistrict?.call(district.district);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              district.district,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              district.localizedStatus(languageCode),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.ink3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${district.visitedCount}/${district.totalPlaces} (${district.coveragePercent}%)',
                          style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: district.coveragePercent >= 70
                                ? AppColors.orange
                                : AppColors.ink2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        children: [
                          Container(height: 4, width: double.infinity, color: AppColors.paper3),
                          FractionallySizedBox(
                            widthFactor: district.coverageFraction,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: district.coveragePercent >= 70
                                    ? AppColors.orange
                                    : AppColors.cobalt,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Recommended Gem Callout
          if (report.recommendedPlaceName != null && report.recommendedPlaceId != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.butterSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('✨', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UNCOVER NEXT IN ${report.recommendedDistrict?.toUpperCase()}',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink3,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          report.recommendedPlaceName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticService.selection();
                      onTapRecommendation?.call(report.recommendedPlaceId!);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View Spot',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
