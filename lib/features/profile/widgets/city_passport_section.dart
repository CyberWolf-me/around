import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/metro_stamp_engine.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/metro_stamp_repository.dart';
import '../../../data/repositories/district_crown_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/haptic_service.dart';

final cityPassportMetroStampsProvider = FutureProvider<List<MetroStamp>>((ref) async {
  final repo = ref.watch(metroStampRepositoryProvider);
  return repo.getUserStamps();
});

final metroStampRepositoryProvider = Provider<MetroStampRepository>((ref) {
  return MetroStampRepository();
});

final districtCrownRepositoryProvider = Provider<DistrictCrownRepository>((ref) {
  return DistrictCrownRepository();
});

/// Unified City Passport Section combining District Passport Stamps & Territory Crowns (`P50-02`).
/// Retains the two high-signal spatial mechanics while eliminating redundant gamification clutter.
class CityPassportSection extends ConsumerStatefulWidget {
  final ProfileModel profile;
  final String locale;

  const CityPassportSection({
    super.key,
    required this.profile,
    this.locale = 'en',
  });

  @override
  ConsumerState<CityPassportSection> createState() => _CityPassportSectionState();
}

class _CityPassportSectionState extends ConsumerState<CityPassportSection> {
  int _selectedTab = 0; // 0 = District & Metro Stamps, 1 = Territory Crowns

  static const List<String> _tashkentDistricts = [
    'Mirabad',
    'Yakkasaray',
    'Shaykhontohur',
    'Yunusabad',
    'Chilanzar',
    'Mirzo Ulugbek',
    'Almazar',
    'Uchtepa',
    'Yashnabad',
    'Sergeli',
    'Yangihayot',
    'Bektemir',
  ];

  @override
  Widget build(BuildContext context) {
    final placesRepo = ref.watch(placesRepositoryProvider);
    final allPlaces = placesRepo.getAllPlaces();
    final myDrops = ref.watch(postsRepositoryProvider).where((p) => p.authorId == widget.profile.id || p.authorId == 'you').toList();
    final visitedDistricts = myDrops
        .map((d) => allPlaces.where((p) => p.id == d.placeId).firstOrNull?.district)
        .whereType<String>()
        .toSet();

    final stampsAsync = ref.watch(cityPassportMetroStampsProvider);
    final claimedStamps = stampsAsync.asData?.value ?? const <MetroStamp>[];

    return Container(
      key: const Key('city_passport_section'),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [AppColors.shadowCard],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.ink,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TASHKENT CITY PASSPORT',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.paper,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.butter,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ink, width: 1),
                  ),
                  child: Text(
                    '${visitedDistricts.length}/12 DISTRICTS',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sub-Tab Switcher: Stamps vs Territory Crowns
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.paper2,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    key: const Key('tab_passport_stamps'),
                    onTap: () {
                      HapticService.selection();
                      setState(() => _selectedTab = 0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? AppColors.paper : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: _selectedTab == 0
                            ? Border.all(color: AppColors.borderSubtle, width: 1.2)
                            : null,
                        boxShadow: _selectedTab == 0 ? const [AppColors.shadowSubtle] : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏷️', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                            'District & Metro Stamps',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w600,
                              color: _selectedTab == 0 ? AppColors.ink : AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    key: const Key('tab_territory_crowns'),
                    onTap: () {
                      HapticService.selection();
                      setState(() => _selectedTab = 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? AppColors.paper : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: _selectedTab == 1
                            ? Border.all(color: AppColors.borderSubtle, width: 1.2)
                            : null,
                        boxShadow: _selectedTab == 1 ? const [AppColors.shadowSubtle] : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('👑', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                            'Territory Crowns',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w600,
                              color: _selectedTab == 1 ? AppColors.ink : AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: _selectedTab == 0
                ? _buildStampsView(visitedDistricts, claimedStamps)
                : _buildCrownsView(visitedDistricts, myDrops.length),
          ),
        ],
      ),
    );
  }

  Widget _buildStampsView(Set<String> visitedDistricts, List<MetroStamp> claimedStamps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '12 Tashkent Districts',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            Text(
              '${(visitedDistricts.length / 12 * 100).round()}% Explored',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tashkentDistricts.map((district) {
            final isVisited = visitedDistricts.contains(district) ||
                (widget.profile.neighborhood.contains(district));
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isVisited ? AppColors.mintSubtle : AppColors.paper2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isVisited ? AppColors.mint : AppColors.borderHairline,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isVisited ? '✓' : '○',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isVisited ? const Color(0xFF2E7D32) : AppColors.ink3,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    district,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: isVisited ? FontWeight.bold : FontWeight.w500,
                      color: isVisited ? AppColors.ink : AppColors.ink3,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.borderHairline, height: 1),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ceramic Metro Seals',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            Text(
              '3 Lines Active',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: AppColors.ink3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildMetroLinePill('Chilanzar Red', const Color(0xFFE53935)),
            const SizedBox(width: 8),
            _buildMetroLinePill('Uzbekistan Blue', const Color(0xFF1E88E5)),
            const SizedBox(width: 8),
            _buildMetroLinePill('Yunusabad Green', const Color(0xFF43A047)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetroLinePill(String name, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildCrownsView(Set<String> visitedDistricts, int dropCount) {
    final neighborhood = widget.profile.neighborhood.isNotEmpty
        ? widget.profile.neighborhood
        : 'Mirabad';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Territory Crowns ("Strava for Places")',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.butter,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.ink, width: 1),
              ),
              child: Text(
                'LIVE STANDINGS',
                style: GoogleFonts.spaceMono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.butter,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('👑', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$neighborhood Tastemaker',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rank #1 local tastemaker · $dropCount verified drops',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 11.5,
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Crowns are earned by check-in density, high-signal recommendations, and friend saves in each neighborhood.',
          style: GoogleFonts.instrumentSans(
            fontSize: 11,
            color: AppColors.ink3,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
