/// Curator Tier categories in Around's Strava-style progression.
enum CuratorTier {
  neighborhoodScout,
  districtCurator,
  cityPioneer,
  tashkentLegend,
}

extension CuratorTierExtension on CuratorTier {
  int get level {
    switch (this) {
      case CuratorTier.neighborhoodScout:
        return 1;
      case CuratorTier.districtCurator:
        return 2;
      case CuratorTier.cityPioneer:
        return 3;
      case CuratorTier.tashkentLegend:
        return 4;
    }
  }

  String get titleUz {
    switch (this) {
      case CuratorTier.neighborhoodScout:
        return 'Mahalla Izquvari';
      case CuratorTier.districtCurator:
        return 'Tuman Kuratori';
      case CuratorTier.cityPioneer:
        return 'Shahar Keshfiyotchisi';
      case CuratorTier.tashkentLegend:
        return 'Toshkent Afsonasi';
    }
  }

  String get titleRu {
    switch (this) {
      case CuratorTier.neighborhoodScout:
        return 'Разведчик района';
      case CuratorTier.districtCurator:
        return 'Куратор района';
      case CuratorTier.cityPioneer:
        return 'Городской пионер';
      case CuratorTier.tashkentLegend:
        return 'Легенда Ташкента';
    }
  }

  String get titleEn {
    switch (this) {
      case CuratorTier.neighborhoodScout:
        return 'Neighborhood Scout';
      case CuratorTier.districtCurator:
        return 'District Curator';
      case CuratorTier.cityPioneer:
        return 'City Pioneer';
      case CuratorTier.tashkentLegend:
        return 'Tashkent Legend';
    }
  }

  String get badgeEmoji {
    switch (this) {
      case CuratorTier.neighborhoodScout:
        return '🌱';
      case CuratorTier.districtCurator:
        return '🧭';
      case CuratorTier.cityPioneer:
        return '⚡';
      case CuratorTier.tashkentLegend:
        return '👑';
    }
  }

  int get badgeColorHex {
    switch (this) {
      case CuratorTier.neighborhoodScout:
        return 0xFF8E8877; // Muted Ink
      case CuratorTier.districtCurator:
        return 0xFF2B4CFF; // Cobalt Blue
      case CuratorTier.cityPioneer:
        return 0xFFFF5A1F; // Brand Orange
      case CuratorTier.tashkentLegend:
        return 0xFFFFD666; // Golden Crown
    }
  }
}

/// Calculated curator progression status.
class CuratorProgression {
  final int totalXp;
  final CuratorTier tier;
  final int level;
  final int currentTierBaseXp;
  final int? nextTierBaseXp;
  final double progressFraction;
  final int xpToNextTier;
  final int dropsCount;
  final int streakWeeks;
  final int districtCrowns;

  const CuratorProgression({
    required this.totalXp,
    required this.tier,
    required this.level,
    required this.currentTierBaseXp,
    required this.nextTierBaseXp,
    required this.progressFraction,
    required this.xpToNextTier,
    required this.dropsCount,
    required this.streakWeeks,
    required this.districtCrowns,
  });

  String localizedTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return tier.titleUz;
      case 'ru':
        return tier.titleRu;
      case 'en':
      default:
        return tier.titleEn;
    }
  }

  String formattedProgressLabel(String lang) {
    if (nextTierBaseXp == null) {
      switch (lang.toLowerCase()) {
        case 'uz':
          return 'Eng yuqori cho‘qqi!';
        case 'ru':
          return 'Максимальный уровень!';
        case 'en':
        default:
          return 'Max Level Reached!';
      }
    }

    switch (lang.toLowerCase()) {
      case 'uz':
        return 'Keyingi darajagacha $xpToNextTier XP';
      case 'ru':
        return 'До след. уровня: $xpToNextTier XP';
      case 'en':
      default:
        return '$xpToNextTier XP to next level';
    }
  }
}

/// Curator Badging & Level Progression Engine (`P23-01`).
/// Translates verified drops, active streaks, and district crowns into XP and tiers.
class CuratorProgressionEngine {
  static const int xpPerDrop = 50;
  static const int xpPerStreakWeek = 100;
  static const int xpPerCrown = 250;

  static const int tier1Threshold = 0;
  static const int tier2Threshold = 250;
  static const int tier3Threshold = 750;
  static const int tier4Threshold = 2000;

  /// Computes total XP and derived tier status.
  static CuratorProgression calculate({
    required int dropsCount,
    required int streakWeeks,
    int districtCrowns = 0,
    int bonusXp = 0,
  }) {
    final safeDrops = dropsCount < 0 ? 0 : dropsCount;
    final safeStreaks = streakWeeks < 0 ? 0 : streakWeeks;
    final safeCrowns = districtCrowns < 0 ? 0 : districtCrowns;
    final safeBonus = bonusXp < 0 ? 0 : bonusXp;

    final totalXp = (safeDrops * xpPerDrop) +
        (safeStreaks * xpPerStreakWeek) +
        (safeCrowns * xpPerCrown) +
        safeBonus;

    CuratorTier tier;
    int currentBase;
    int? nextBase;

    if (totalXp >= tier4Threshold) {
      tier = CuratorTier.tashkentLegend;
      currentBase = tier4Threshold;
      nextBase = null;
    } else if (totalXp >= tier3Threshold) {
      tier = CuratorTier.cityPioneer;
      currentBase = tier3Threshold;
      nextBase = tier4Threshold;
    } else if (totalXp >= tier2Threshold) {
      tier = CuratorTier.districtCurator;
      currentBase = tier2Threshold;
      nextBase = tier3Threshold;
    } else {
      tier = CuratorTier.neighborhoodScout;
      currentBase = tier1Threshold;
      nextBase = tier2Threshold;
    }

    double progress;
    int remaining;

    if (nextBase == null) {
      progress = 1.0;
      remaining = 0;
    } else {
      final range = nextBase - currentBase;
      final currentInTier = totalXp - currentBase;
      progress = (currentInTier / range).clamp(0.0, 1.0);
      remaining = nextBase - totalXp;
    }

    return CuratorProgression(
      totalXp: totalXp,
      tier: tier,
      level: tier.level,
      currentTierBaseXp: currentBase,
      nextTierBaseXp: nextBase,
      progressFraction: progress,
      xpToNextTier: remaining,
      dropsCount: safeDrops,
      streakWeeks: safeStreaks,
      districtCrowns: safeCrowns,
    );
  }
}
