import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available trophy accomplishment tiers for monthly seasons.
enum CuratorTrophyTier {
  bronze,
  silver,
  gold;

  String get id => name;

  String get emoji {
    switch (this) {
      case CuratorTrophyTier.gold:
        return '🥇';
      case CuratorTrophyTier.silver:
        return '🥈';
      case CuratorTrophyTier.bronze:
        return '🥉';
    }
  }
}

/// A specific monthly exploration goal in Tashkent.
class SeasonalChallenge {
  final String id;
  final String titleEn;
  final String titleUz;
  final String titleRu;
  final String descriptionEn;
  final String descriptionUz;
  final String descriptionRu;
  final String icon;
  final int targetCount;
  final int currentCount;
  final int xpReward;

  const SeasonalChallenge({
    required this.id,
    required this.titleEn,
    required this.titleUz,
    required this.titleRu,
    required this.descriptionEn,
    required this.descriptionUz,
    required this.descriptionRu,
    required this.icon,
    required this.targetCount,
    this.currentCount = 0,
    required this.xpReward,
  });

  bool get isCompleted => currentCount >= targetCount;

  double get progressPercentage {
    if (targetCount <= 0) return 0.0;
    final ratio = currentCount / targetCount;
    return ratio.clamp(0.0, 1.0);
  }

  String getLocalizedTitle(String language) {
    switch (language.toLowerCase()) {
      case 'uz':
        return titleUz;
      case 'ru':
        return titleRu;
      case 'en':
      default:
        return titleEn;
    }
  }

  String getLocalizedDescription(String language) {
    switch (language.toLowerCase()) {
      case 'uz':
        return descriptionUz;
      case 'ru':
        return descriptionRu;
      case 'en':
      default:
        return descriptionEn;
    }
  }

  SeasonalChallenge copyWith({int? currentCount}) {
    return SeasonalChallenge(
      id: id,
      titleEn: titleEn,
      titleUz: titleUz,
      titleRu: titleRu,
      descriptionEn: descriptionEn,
      descriptionUz: descriptionUz,
      descriptionRu: descriptionRu,
      icon: icon,
      targetCount: targetCount,
      currentCount: currentCount ?? this.currentCount,
      xpReward: xpReward,
    );
  }
}

/// Full state of a monthly exploration season.
class CuratorSeason {
  final String seasonId; // e.g. "2026-11"
  final String titleEn;
  final String titleUz;
  final String titleRu;
  final DateTime startDate;
  final DateTime endDate;
  final List<SeasonalChallenge> challenges;

  const CuratorSeason({
    required this.seasonId,
    required this.titleEn,
    required this.titleUz,
    required this.titleRu,
    required this.startDate,
    required this.endDate,
    required this.challenges,
  });

  int get completedCount => challenges.where((c) => c.isCompleted).length;

  int get totalChallenges => challenges.length;

  double get overallProgress {
    if (challenges.isEmpty) return 0.0;
    return (completedCount / challenges.length).clamp(0.0, 1.0);
  }

  int get totalXpAvailable => challenges.fold(0, (sum, c) => sum + c.xpReward);

  int get totalXpEarned => challenges.where((c) => c.isCompleted).fold(0, (sum, c) => sum + c.xpReward);

  CuratorTrophyTier? get earnedTrophyTier {
    if (completedCount >= 3) return CuratorTrophyTier.gold;
    if (completedCount == 2) return CuratorTrophyTier.silver;
    if (completedCount == 1) return CuratorTrophyTier.bronze;
    return null;
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays.clamp(0, 31);
  }

  String getLocalizedTitle(String language) {
    switch (language.toLowerCase()) {
      case 'uz':
        return titleUz;
      case 'ru':
        return titleRu;
      case 'en':
      default:
        return titleEn;
    }
  }
}

/// Core computational engine for monthly curator exploration seasons.
class SeasonTrophyEngine {
  /// Generates the standard season ID from a reference date (e.g. "2026-11").
  static String getSeasonId(DateTime date) {
    final monthStr = date.month.toString().padLeft(2, '0');
    return '${date.year}-$monthStr';
  }

  /// Calculates days remaining between a reference time and the end of the season.
  static int calculateDaysRemaining(DateTime endDate, [DateTime? now]) {
    final ref = now ?? DateTime.now();
    if (ref.isAfter(endDate)) return 0;
    return endDate.difference(ref).inDays.clamp(0, 31);
  }

  /// Evaluates overall earned trophy tier from completed count.
  static CuratorTrophyTier? evaluateOverallTier(int completedCount) {
    if (completedCount >= 3) return CuratorTrophyTier.gold;
    if (completedCount == 2) return CuratorTrophyTier.silver;
    if (completedCount == 1) return CuratorTrophyTier.bronze;
    return null;
  }

  /// Localized name of a trophy tier.
  static String getLocalizedTierName(CuratorTrophyTier tier, String language) {
    switch (tier) {
      case CuratorTrophyTier.gold:
        switch (language.toLowerCase()) {
          case 'uz':
            return 'Oltin Kubok';
          case 'ru':
            return 'Золотой Трофей';
          case 'en':
          default:
            return 'Gold Trophy';
        }
      case CuratorTrophyTier.silver:
        switch (language.toLowerCase()) {
          case 'uz':
            return 'Kumush Kubok';
          case 'ru':
            return 'Серебряный Трофей';
          case 'en':
          default:
            return 'Silver Trophy';
        }
      case CuratorTrophyTier.bronze:
        switch (language.toLowerCase()) {
          case 'uz':
            return 'Bronza Kubok';
          case 'ru':
            return 'Бронзовый Трофей';
          case 'en':
          default:
            return 'Bronze Trophy';
        }
    }
  }

  /// Returns the current active season populated with challenge progress.
  static CuratorSeason getCurrentSeason({
    DateTime? referenceDate,
    int districtCount = 0,
    int metroCount = 0,
    int weekendCount = 0,
  }) {
    final now = referenceDate ?? DateTime.now();
    final seasonId = getSeasonId(now);

    final start = DateTime(now.year, now.month, 1);
    // End of the month
    final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
    final end = nextMonth.subtract(const Duration(seconds: 1));

    final challenges = [
      SeasonalChallenge(
        id: 'district_explorer',
        titleEn: 'District Pioneer',
        titleUz: 'Tuman Kashfiyotchisi',
        titleRu: 'Первопроходец Районов',
        descriptionEn: 'Discover verified places across 3 distinct Tashkent districts',
        descriptionUz: 'Toshkentning 3 ta turli tumanida tasdiqlangan joylarni kashf eting',
        descriptionRu: 'Посетите проверенные места в 3 различных районах Ташкента',
        icon: '🧭',
        targetCount: 3,
        currentCount: districtCount.clamp(0, 3),
        xpReward: 200,
      ),
      SeasonalChallenge(
        id: 'metro_nomad',
        titleEn: 'Metro Line Nomad',
        titleUz: 'Metro Chizig‘i Sayyohi',
        titleRu: 'Кочевник Метрополитена',
        descriptionEn: 'Check in near 3 different Tashkent subway stations',
        descriptionUz: 'Toshkent metrosining 3 ta turli bekati yaqinida ro‘yxatdan o‘ting',
        descriptionRu: 'Сделайте отметки около 3 разных станций ташкентского метро',
        icon: '🚇',
        targetCount: 3,
        currentCount: metroCount.clamp(0, 3),
        xpReward: 150,
      ),
      SeasonalChallenge(
        id: 'weekend_rhythm',
        titleEn: 'Weekend Taste Scout',
        titleUz: 'Dam Olish Kunlari Skauti',
        titleRu: 'Скаут Выходного Дня',
        descriptionEn: 'Create 2 place drops during weekend hours',
        descriptionUz: 'Dam olish kunlarida 2 ta joy xotirasini ulashing',
        descriptionRu: 'Опубликуйте 2 заметки в выходные дни',
        icon: '☕',
        targetCount: 2,
        currentCount: weekendCount.clamp(0, 2),
        xpReward: 150,
      ),
    ];

    String titleEn;
    String titleUz;
    String titleRu;

    switch (now.month) {
      case 11:
        titleEn = 'Autumn in Tashkent';
        titleUz = 'Toshkentda Kuz';
        titleRu = 'Осень в Ташкенте';
        break;
      case 12:
        titleEn = 'Winter Lights of Tashkent';
        titleUz = 'Toshkent Qishki Chiroqlari';
        titleRu = 'Зимние Огни Ташкента';
        break;
      default:
        titleEn = 'Tashkent Urban Explorer';
        titleUz = 'Toshkent Shahar Sayyohi';
        titleRu = 'Исследователь Ташкента';
        break;
    }

    return CuratorSeason(
      seasonId: seasonId,
      titleEn: titleEn,
      titleUz: titleUz,
      titleRu: titleRu,
      startDate: start,
      endDate: end,
      challenges: challenges,
    );
  }
}

final seasonTrophyEngineProvider = Provider<SeasonTrophyEngine>((ref) {
  return SeasonTrophyEngine();
});

final currentSeasonProvider = Provider<CuratorSeason>((ref) {
  return SeasonTrophyEngine.getCurrentSeason();
});
