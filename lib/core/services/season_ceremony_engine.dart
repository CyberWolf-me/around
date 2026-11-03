import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Achievement laurels awarded at monthly season rollover.
enum CuratorLaurelTier {
  champion, // #1 in district or city
  podium,   // Top 2-3
  topTen,   // Top 4-10
  explorer; // Top 11+

  String get id => name;

  String get badgeIcon {
    switch (this) {
      case CuratorLaurelTier.champion:
        return '👑';
      case CuratorLaurelTier.podium:
        return '🥈';
      case CuratorLaurelTier.topTen:
        return '🥉';
      case CuratorLaurelTier.explorer:
        return '🎖️';
    }
  }
}

/// Comprehensive end-of-season summary metrics for a curator.
class SeasonWrapupReport {
  final String seasonId;
  final String seasonTitleEn;
  final String seasonTitleUz;
  final String seasonTitleRu;
  final int totalSeasonXp;
  final int totalPlacesVisited;
  final String topDistrict;
  final int districtRank;
  final int cityRank;
  final CuratorLaurelTier laurelTier;
  final int crownsAwarded;
  final int bonusXpAwarded;

  const SeasonWrapupReport({
    required this.seasonId,
    required this.seasonTitleEn,
    required this.seasonTitleUz,
    required this.seasonTitleRu,
    required this.totalSeasonXp,
    required this.totalPlacesVisited,
    required this.topDistrict,
    required this.districtRank,
    required this.cityRank,
    required this.laurelTier,
    required this.crownsAwarded,
    required this.bonusXpAwarded,
  });

  bool get isChampion => laurelTier == CuratorLaurelTier.champion;

  String getLocalizedSeasonTitle(String language) {
    switch (language.toLowerCase()) {
      case 'uz':
        return seasonTitleUz;
      case 'ru':
        return seasonTitleRu;
      case 'en':
      default:
        return seasonTitleEn;
    }
  }
}

/// Core computational engine for monthly curator ceremony awards (`P30-01`).
class SeasonCeremonyEngine {
  /// Evaluates the laurel tier based on final district placement.
  static CuratorLaurelTier evaluateLaurel(int districtRank) {
    if (districtRank <= 0) return CuratorLaurelTier.explorer;
    if (districtRank == 1) return CuratorLaurelTier.champion;
    if (districtRank <= 3) return CuratorLaurelTier.podium;
    if (districtRank <= 10) return CuratorLaurelTier.topTen;
    return CuratorLaurelTier.explorer;
  }

  /// Calculates celebration bonus XP granted for the achieved laurel tier.
  static int calculateCeremonyBonusXp(CuratorLaurelTier tier) {
    switch (tier) {
      case CuratorLaurelTier.champion:
        return 500;
      case CuratorLaurelTier.podium:
        return 250;
      case CuratorLaurelTier.topTen:
        return 100;
      case CuratorLaurelTier.explorer:
        return 50;
    }
  }

  /// Generates a structured wrap-up report for the concluded season.
  static SeasonWrapupReport generateWrapupReport({
    required String seasonId,
    String seasonTitleEn = 'Autumn in Tashkent',
    String seasonTitleUz = 'Toshkentda Kuz',
    String seasonTitleRu = 'Осень в Ташкенте',
    required int totalSeasonXp,
    required int totalPlacesVisited,
    required String topDistrict,
    required int districtRank,
    required int cityRank,
  }) {
    final laurel = evaluateLaurel(districtRank);
    final crowns = laurel == CuratorLaurelTier.champion ? 1 : 0;
    final bonusXp = calculateCeremonyBonusXp(laurel);

    return SeasonWrapupReport(
      seasonId: seasonId,
      seasonTitleEn: seasonTitleEn,
      seasonTitleUz: seasonTitleUz,
      seasonTitleRu: seasonTitleRu,
      totalSeasonXp: totalSeasonXp,
      totalPlacesVisited: totalPlacesVisited,
      topDistrict: topDistrict,
      districtRank: districtRank > 0 ? districtRank : 1,
      cityRank: cityRank > 0 ? cityRank : 1,
      laurelTier: laurel,
      crownsAwarded: crowns,
      bonusXpAwarded: bonusXp,
    );
  }

  /// Localized name of the laurel tier.
  static String getLocalizedLaurelName(CuratorLaurelTier tier, String language) {
    switch (tier) {
      case CuratorLaurelTier.champion:
        switch (language.toLowerCase()) {
          case 'uz':
            return 'Tuman Chempioni Toji';
          case 'ru':
            return 'Корона Чемпиона Района';
          case 'en':
          default:
            return 'District Champion Crown';
        }
      case CuratorLaurelTier.podium:
        switch (language.toLowerCase()) {
          case 'uz':
            return 'Kumush Lavr Medali';
          case 'ru':
            return 'Серебряный Лавровый Венок';
          case 'en':
          default:
            return 'Silver Podium Laurel';
        }
      case CuratorLaurelTier.topTen:
        switch (language.toLowerCase()) {
          case 'uz':
            return 'Top-10 Bronza Lavr';
          case 'ru':
            return 'Бронзовый Лавр Топ-10';
          case 'en':
          default:
            return 'Top 10 Bronze Laurel';
        }
      case CuratorLaurelTier.explorer:
        switch (language.toLowerCase()) {
          case 'uz':
            return 'Kashfiyotchi Nishoni';
          case 'ru':
            return 'Лента Исследователя';
          case 'en':
          default:
            return 'Explorer Season Ribbon';
        }
    }
  }

  /// Localized headline for the ceremony dialog.
  static String getLocalizedCelebrationHeadline(SeasonWrapupReport report, String language) {
    final lang = language.toLowerCase();
    final district = report.topDistrict;

    if (report.isChampion) {
      switch (lang) {
        case 'uz':
          return 'Tabriklaymiz! Siz $district Tuman Chempionisiz!';
        case 'ru':
          return 'Поздравляем! Вы Чемпион Района $district!';
        case 'en':
          return 'Congratulations! You are the $district Champion!';
      }
    }

    switch (lang) {
      case 'uz':
        return '$district Tumanida #${report.districtRank}-O‘rinni Egalladingiz!';
      case 'ru':
        return 'Вы заняли #${report.districtRank} место в районе $district!';
      case 'en':
      default:
        return 'You placed #${report.districtRank} in $district!';
    }
  }
}

final seasonCeremonyEngineProvider = Provider<SeasonCeremonyEngine>((ref) {
  return SeasonCeremonyEngine();
});
