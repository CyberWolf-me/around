import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/taste_archetype_engine.dart';
import '../../../data/models/place_model.dart';

/// High-aesthetic Taste Radar & Explorer Archetype visualizer (`P15-02`).
/// Displays multi-axis taste dimension bars and calculated curator archetype
/// within the Tashkent Taste Passport.
class TasteRadarWidget extends StatelessWidget {
  final List<PlaceModel> places;
  final String languageCode;
  final TasteRadarProfile? customProfile;

  const TasteRadarWidget({
    super.key,
    required this.places,
    this.languageCode = 'en',
    this.customProfile,
  });

  Color _getDimensionColor(TasteDimension dim) {
    switch (dim) {
      case TasteDimension.specialtyCoffee:
        return AppColors.orange;
      case TasteDimension.nationalDining:
        return AppColors.butter;
      case TasteDimension.nightlifeAndSocial:
        return AppColors.blush;
      case TasteDimension.artsAndCulture:
        return AppColors.cobalt;
      case TasteDimension.parksAndGreen:
        return AppColors.mint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = customProfile ?? TasteArchetypeEngine.analyze(places);

    return Container(
      key: const Key('taste_radar_widget'),
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Archetype Title & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Urban Taste Radar',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(profile.archetypeIcon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      profile.getArchetypeTitle(languageCode),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.getDescription(languageCode),
            style: GoogleFonts.instrumentSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.ink2,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Multi-axis dimension bars
          ...TasteDimension.values.map((dim) {
            final weight = profile.dimensionWeights[dim] ?? 0.0;
            final percent = (weight * 100).toInt();
            final barColor = _getDimensionColor(dim);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dim.icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                            dim.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$percent%',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 6,
                      color: AppColors.paper2,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: weight.clamp(0.04, 1.0),
                        child: Container(color: barColor),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          // Footer: Diversity Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Curator Footprint',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink3,
                ),
              ),
              Text(
                'Diversity Index: ${(profile.diversityScore * 100).toInt()}% · ${profile.totalVenuesAnalyzed} spots',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
