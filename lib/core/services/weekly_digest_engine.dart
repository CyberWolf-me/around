import '../../data/models/place_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/places_repository.dart';
import 'atmosphere_service.dart';

/// Weekly Urban Momentum Digest Model for Tashkent (`P14-04`).
class WeeklyDigest {
  final int totalWeeklyDrops;
  final String topDistrict;
  final int topDistrictDropCount;
  final PlaceModel? trendingVenue;
  final int trendingVenueDropCount;
  final AtmosphereMode dominantAtmosphere;
  final DateTime generatedAt;
  final String promptUz;
  final String promptRu;
  final String promptEn;

  const WeeklyDigest({
    required this.totalWeeklyDrops,
    required this.topDistrict,
    required this.topDistrictDropCount,
    this.trendingVenue,
    required this.trendingVenueDropCount,
    required this.dominantAtmosphere,
    required this.generatedAt,
    required this.promptUz,
    required this.promptRu,
    required this.promptEn,
  });

  /// Returns localized prompt for the given language code ('uz', 'ru', 'en').
  String getPrompt(String langCode) {
    switch (langCode.toLowerCase().trim()) {
      case 'uz':
        return promptUz;
      case 'ru':
        return promptRu;
      case 'en':
      default:
        return promptEn;
    }
  }

  /// Formats an actionable weekend invite message for friends.
  String generateWeekendInviteMessage(String langCode, {String? customPlaceName}) {
    final venueName = customPlaceName ?? trendingVenue?.name ?? 'our favorite café';
    switch (langCode.toLowerCase().trim()) {
      case 'uz':
        return "Salom! Ushbu haftada $topDistrict juda jonli bo'ldi ($topDistrictDropCount ta tavsiya). "
            "Dam olish kuni $venueName da ko'rishamizmi? https://around.tashkent.app";
      case 'ru':
        return "Привет! На этой неделе в районе $topDistrict было оживленно ($topDistrictDropCount дропов). "
            "Встретимся на выходных в $venueName? https://around.tashkent.app";
      case 'en':
      default:
        return "Hey! $topDistrict was buzzing with $topDistrictDropCount drops this week. "
            "Want to meet up at $venueName this weekend? https://around.tashkent.app";
    }
  }
}

/// Local Weekly Rhythm Digest & Weekend Social Re-engagement Engine (`P14-04`).
/// Aggregates social momentum from the past 7 days across Tashkent districts
/// and synthesizes culturally tuned weekend discovery prompts.
class WeeklyDigestEngine {
  /// Evaluates whether the reference time falls into the weekend engagement window
  /// (Friday 16:00 through Sunday 23:59).
  static bool isWeekendWindow(DateTime now) {
    final weekday = now.weekday; // 1 = Mon, 5 = Fri, 6 = Sat, 7 = Sun
    if (weekday == DateTime.friday && now.hour >= 16) return true;
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) return true;
    return false;
  }

  /// Computes the 7-day weekly digest from drops and place metadata.
  static WeeklyDigest generateWeeklyDigest({
    required List<PostModel> drops,
    required List<PlaceModel> places,
    List<DistrictDensityModel>? districtDensities,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Filter drops within past 7 days
    final weeklyDrops = drops.where((d) {
      return d.createdAt.isAfter(sevenDaysAgo) || d.createdAt.isAtSameMomentAs(sevenDaysAgo);
    }).toList();

    // Map placeId to PlaceModel and district lookup
    final placeMap = <String, PlaceModel>{};
    final placeDistrictMap = <String, String>{};
    for (final p in places) {
      placeMap[p.id] = p;
      placeMap[p.slug] = p;
      placeDistrictMap[p.id] = p.district;
      placeDistrictMap[p.slug] = p.district;
    }

    // Tally drops by venue and district
    final venueCounts = <String, int>{};
    final districtCounts = <String, int>{};
    final atmosphereCounts = <AtmosphereMode, int>{
      AtmosphereMode.morningBrew: 0,
      AtmosphereMode.afternoonFocus: 0,
      AtmosphereMode.goldenHour: 0,
      AtmosphereMode.lateNightVinyl: 0,
    };

    for (final drop in weeklyDrops) {
      venueCounts[drop.placeId] = (venueCounts[drop.placeId] ?? 0) + 1;

      final district = placeDistrictMap[drop.placeId] ?? 'Central Tashkent';
      districtCounts[district] = (districtCounts[district] ?? 0) + 1;

      final mode = AtmosphereService.getModeForHour(drop.createdAt.hour);
      atmosphereCounts[mode] = (atmosphereCounts[mode] ?? 0) + 1;
    }

    // Determine top district
    String topDistrict = 'Mirabad';
    int topDistrictCount = 0;
    if (districtCounts.isNotEmpty) {
      final sortedDistricts = districtCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topDistrict = sortedDistricts.first.key;
      topDistrictCount = sortedDistricts.first.value;
    } else if (districtDensities != null && districtDensities.isNotEmpty) {
      final topDensity = districtDensities.reduce((a, b) => a.dropCount >= b.dropCount ? a : b);
      topDistrict = topDensity.district;
      topDistrictCount = topDensity.dropCount;
    }

    // Determine trending venue
    PlaceModel? trendingVenue;
    int trendingVenueCount = 0;
    if (venueCounts.isNotEmpty) {
      final sortedVenues = venueCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topVenueId = sortedVenues.first.key;
      trendingVenue = placeMap[topVenueId];
      trendingVenueCount = sortedVenues.first.value;
    }

    // Fallback if no trending venue found from drops
    if (trendingVenue == null && places.isNotEmpty) {
      trendingVenue = places.firstWhere(
        (p) => p.district.toLowerCase() == topDistrict.toLowerCase(),
        orElse: () => places.first,
      );
    }

    // Determine dominant atmosphere
    AtmosphereMode dominantAtmosphere = AtmosphereMode.goldenHour;
    int maxAtmosphereCount = -1;
    for (final entry in atmosphereCounts.entries) {
      if (entry.value > maxAtmosphereCount) {
        maxAtmosphereCount = entry.value;
        dominantAtmosphere = entry.key;
      }
    }
    if (maxAtmosphereCount <= 0) {
      dominantAtmosphere = AtmosphereService.getModeForHour(now.hour);
    }

    final totalDrops = weeklyDrops.length;
    final venueName = trendingVenue?.name ?? 'Tashkent hotspots';

    // Synthesize culturally tuned prompts depending on day and time
    final isFridayEvening = now.weekday == DateTime.friday && now.hour >= 16;
    final isSaturdayMorning = now.weekday == DateTime.saturday && now.hour < 14;

    String promptEn;
    String promptRu;
    String promptUz;

    if (isFridayEvening) {
      promptEn = '🔥 Friday night in Tashkent: $topDistrict is buzzing ($topDistrictCount drops this week). Gather your circle at $venueName!';
      promptRu = '🔥 Пятничный вечер в Ташкенте: район $topDistrict на пике ($topDistrictCount дропов). Соберите компанию в $venueName!';
      promptUz = "🔥 Toshkentda juma oqshomi: $topDistrict tumanida qizg'in kayfiyat ($topDistrictCount ta tavsiya). Do'stlar bilan $venueName da uchrashing!";
    } else if (isSaturdayMorning) {
      promptEn = '☕ Saturday rhythm: Mirabad croissants and calm morning light. Catch up with friends at $venueName today.';
      promptRu = '☕ Субботний ритм: утренний кофе и свежие круассаны. Самое время встретиться с друзьями в $venueName.';
      promptUz = "☕ Shanba tongi maromi: issiq qahva va shinam suhbat. Bugun $venueName da do'stlar bilan diydor ko'rishish vaqti.";
    } else {
      promptEn = '✨ Weekly Rhythm: $totalDrops drops shared across Tashkent this week. Most active neighborhood: $topDistrict.';
      promptRu = '✨ Недельный ритм: $totalDrops дропов по Ташкенту за неделю. Лидер активности: $topDistrict.';
      promptUz = "✨ Haftalik marom: Toshkent bo'ylab $totalDrops ta yangi tavsiya. Eng faol tuman: $topDistrict.";
    }

    return WeeklyDigest(
      totalWeeklyDrops: totalDrops,
      topDistrict: topDistrict,
      topDistrictDropCount: topDistrictCount,
      trendingVenue: trendingVenue,
      trendingVenueDropCount: trendingVenueCount,
      dominantAtmosphere: dominantAtmosphere,
      generatedAt: now,
      promptUz: promptUz,
      promptRu: promptRu,
      promptEn: promptEn,
    );
  }
}
