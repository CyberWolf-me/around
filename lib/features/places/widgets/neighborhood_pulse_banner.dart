import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/friend_presence_engine.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/place_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Neighborhood Social Pulse & Friend Activity Map Banner (`P17-02`).
/// Surfaces live friend clustering across Tashkent districts with 1-tap map recentering.
class NeighborhoodPulseBanner extends ConsumerWidget {
  final String? activeDistrict;
  final ValueChanged<String>? onDistrictSelected;
  final List<String>? overrideFriends;
  final List<PostModel>? overrideDrops;
  final List<PlaceModel>? overridePlaces;

  const NeighborhoodPulseBanner({
    super.key,
    this.activeDistrict,
    this.onDistrictSelected,
    this.overrideFriends,
    this.overrideDrops,
    this.overridePlaces,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> friends =
        overrideFriends ?? ref.watch(followedFriendsProvider).toList();
    final List<PostModel> drops =
        overrideDrops ?? ref.watch(postsRepositoryProvider);
    final List<PlaceModel> places =
        overridePlaces ?? ref.watch(placesRepositoryProvider).getAllPlaces();
    final lang = ref.watch(appLocaleProvider);

    final counts = FriendPresenceEngine.getNeighborhoodFriendCounts(
      friendIds: friends,
      drops: drops,
      places: places,
    );

    // Identify hottest district
    String? topDistrict;
    int topCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > topCount) {
        topCount = entry.value;
        topDistrict = entry.key;
      }
    }

    final hasClusters = counts.isNotEmpty && topDistrict != null;

    return Container(
      key: const Key('neighborhood_pulse_banner'),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: const [AppColors.shadowSubtle],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: hasClusters ? AppColors.orangeSubtle : AppColors.paper2,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  hasClusters ? Icons.local_fire_department_rounded : Icons.explore_rounded,
                  size: 16,
                  color: hasClusters ? AppColors.orange : AppColors.ink2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getBannerTitle(hasClusters, lang).toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: hasClusters ? AppColors.orange : AppColors.ink2,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      hasClusters
                          ? _getBannerSubtitle(topDistrict, topCount, lang)
                          : _getQuietSubtitle(lang),
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (counts.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: counts.entries.map((entry) {
                  final district = entry.key;
                  final count = entry.value;
                  final isSelected = activeDistrict?.toLowerCase() == district.toLowerCase();

                  final localizedDistrict = _toLocalizedDistrict(district, lang);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BouncingWidget(
                      onTap: () {
                        HapticService.selection();
                        onDistrictSelected?.call(district);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.ink
                              : (count >= 2 ? AppColors.butterSubtle : AppColors.paper2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.ink
                                : (count >= 2 ? AppColors.butter : AppColors.borderHairline),
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              localizedDistrict,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.orangeSubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _getBannerTitle(bool hasClusters, String lang) {
    switch (lang.toLowerCase().trim()) {
      case 'uz':
        return hasClusters ? 'Qaynoq Nuqta' : 'Toshkent Boʻylab';
      case 'ru':
        return hasClusters ? 'В тренде сейчас' : 'По районам Ташкента';
      case 'en':
      default:
        return hasClusters ? 'Hot Right Now' : 'Around Tashkent';
    }
  }

  static String _getBannerSubtitle(String district, int count, String lang) {
    final uzDistrict = _toLocalizedDistrict(district, 'uz');
    switch (lang.toLowerCase().trim()) {
      case 'uz':
        return '$count ta doʻst $uzDistrict tumanida faol';
      case 'ru':
        return '$count друзей активны в районе $district';
      case 'en':
      default:
        return '$count friend${count > 1 ? 's' : ''} active in $district';
    }
  }

  static String _getQuietSubtitle(String lang) {
    switch (lang.toLowerCase().trim()) {
      case 'uz':
        return 'Barcha tumanlar osoyishta';
      case 'ru':
        return 'Все районы спокойны';
      case 'en':
      default:
        return 'All neighborhoods peaceful';
    }
  }

  static String _toLocalizedDistrict(String district, String lang) {
    if (lang.toLowerCase().trim() == 'uz') {
      switch (district.toLowerCase().trim()) {
        case 'mirabad':
          return 'Mirobod';
        case 'yunusabad':
          return 'Yunusobod';
        case 'yakkasaray':
          return 'Yakkasaroy';
        case 'shaykhontohur':
          return 'Shayxontohur';
        case 'chilanzar':
          return 'Chilonzor';
        case 'central tashkent':
          return 'Markaziy Toshkent';
        default:
          return district;
      }
    }
    return district;
  }
}
