import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/district_legend_engine.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Provider computing active Tashkent District Legends over the rolling 30-day window.
final districtLegendLeaderboardProvider = Provider<DistrictLegendLeaderboard>((ref) {
  final placesRepo = ref.watch(placesRepositoryProvider);
  final drops = ref.watch(postsRepositoryProvider);
  final places = placesRepo.getAllPlaces();

  return DistrictLegendEngine.computeLeaderboard(
    drops: drops,
    places: places,
  );
});

/// Interactive Bottom Sheet displaying Tashkent District Local Legends (`P16-01`).
class DistrictLeaderboardSheet extends ConsumerWidget {
  final DistrictLegendLeaderboard? customLeaderboard;

  const DistrictLeaderboardSheet({super.key, this.customLeaderboard});

  static const canonicalDistricts = [
    'Mirabad',
    'Central Tashkent',
    'Yunusabad',
    'Yakkasaray',
    'Shaykhontohur',
    'Chilanzar',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DistrictLegendLeaderboard leaderboard = customLeaderboard ?? ref.watch(districtLegendLeaderboardProvider);
    final lang = ref.watch(appLocaleProvider);

    return Container(
      key: const Key('district_leaderboard_sheet'),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tashkent Local Legends',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '30-Day Rolling',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The top curator in each neighborhood holding ≥3 drops in the last 30 days holds the Local Legend crown.',
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              color: AppColors.ink2,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // District leaderboard items
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: canonicalDistricts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final district = canonicalDistricts[index];
                final legend = leaderboard.getLegendForDistrict(district);

                if (legend != null) {
                  return Container(
                    key: Key('legend_row_${district.toLowerCase()}'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.orange, width: 1.2),
                      boxShadow: const [AppColors.shadowSubtle],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.orangeSubtle,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.orange, width: 1.2),
                          ),
                          alignment: Alignment.center,
                          child: const Text('👑', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    district,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '· ${legend.userName}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${legend.getBadgeTitle(lang)} (@${legend.username})',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 11,
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.paper2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${legend.dropCount} drops',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Unclaimed state
                return Container(
                  key: Key('legend_unclaimed_${district.toLowerCase()}'),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🏛️', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              district,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink2,
                              ),
                            ),
                            Text(
                              'Crown Unclaimed · Post 3 drops to lead',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 11,
                                color: AppColors.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderHairline),
                        ),
                        child: Text(
                          'Open',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile badge displayed on ProfileScreen when a curator holds a Local Legend crown (`P16-01`).
class LocalLegendBadge extends StatelessWidget {
  final List<DistrictLegend> legends;
  final VoidCallback? onTap;

  const LocalLegendBadge({
    super.key,
    required this.legends,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (legends.isEmpty) return const SizedBox.shrink();

    final districtNames = legends.map((l) => l.district).join(' & ');

    return BouncingWidget(
      scaleFactor: 0.95,
      onTap: () {
        HapticService.selection();
        onTap?.call();
      },
      child: Container(
        key: const Key('profile_local_legend_crown_badge'),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.orangeSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.orange, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$districtNames Local Legend',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}
