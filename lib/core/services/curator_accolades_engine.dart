import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'season_trophy_engine.dart';

/// District placement laurel tier.
enum CuratorLaurelTier {
  champion,
  podium,
  topTen,
  explorer;

  String get id => name;
}

/// Progressive status classification based on cumulative crowns, trophies, and district standing.
enum CuratorMasteryTier {
  grandMaster, // 3+ crowns OR (1+ crown AND 2+ gold trophies)
  legend,      // 1+ crown OR 1+ gold trophy OR 2+ silver trophies
  pioneer,     // 1+ silver/bronze trophy OR 3+ total trophies
  scout;       // Default explorer tier

  String get id => name;

  String get badgeIcon {
    switch (this) {
      case CuratorMasteryTier.grandMaster:
        return '👑⚜️';
      case CuratorMasteryTier.legend:
        return '🌟';
      case CuratorMasteryTier.pioneer:
        return '🧭';
      case CuratorMasteryTier.scout:
        return '🎒';
    }
  }
}

/// A specific earned seasonal trophy record.
class CuratorAccoladeTrophy {
  final String id;
  final String seasonId;
  final String seasonTitle;
  final CuratorTrophyTier tier;
  final int completedChallengesCount;
  final int xpBonus;
  final DateTime earnedAt;

  const CuratorAccoladeTrophy({
    required this.id,
    required this.seasonId,
    required this.seasonTitle,
    required this.tier,
    this.completedChallengesCount = 0,
    this.xpBonus = 0,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'season_id': seasonId,
    'season_title': seasonTitle,
    'tier': tier.name,
    'completed_challenges_count': completedChallengesCount,
    'xp_bonus': xpBonus,
    'earned_at': earnedAt.toIso8601String(),
  };

  factory CuratorAccoladeTrophy.fromJson(Map<String, dynamic> json) {
    CuratorTrophyTier tier = CuratorTrophyTier.bronze;
    final tierStr = (json['tier'] ?? '').toString().toLowerCase();
    if (tierStr == 'gold') {
      tier = CuratorTrophyTier.gold;
    } else if (tierStr == 'silver') {
      tier = CuratorTrophyTier.silver;
    }

    return CuratorAccoladeTrophy(
      id: json['id'] ?? '',
      seasonId: json['season_id'] ?? '',
      seasonTitle: json['season_title'] ?? '',
      tier: tier,
      completedChallengesCount: json['completed_challenges_count'] ?? 0,
      xpBonus: json['xp_bonus'] ?? 0,
      earnedAt: json['earned_at'] != null
          ? DateTime.tryParse(json['earned_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// A specific archived district placement laurel.
class CuratorAccoladeLaurel {
  final String seasonId;
  final String district;
  final int rank;
  final CuratorLaurelTier laurel;

  const CuratorAccoladeLaurel({
    required this.seasonId,
    required this.district,
    required this.rank,
    required this.laurel,
  });

  Map<String, dynamic> toJson() => {
    'season_id': seasonId,
    'district': district,
    'rank': rank,
    'laurel': laurel.name,
  };

  factory CuratorAccoladeLaurel.fromJson(Map<String, dynamic> json) {
    CuratorLaurelTier laurel = CuratorLaurelTier.explorer;
    final laurelStr = (json['laurel'] ?? '').toString().toLowerCase();
    if (laurelStr == 'champion') {
      laurel = CuratorLaurelTier.champion;
    } else if (laurelStr == 'podium') {
      laurel = CuratorLaurelTier.podium;
    } else if (laurelStr == 'topten' || laurelStr == 'top_ten') {
      laurel = CuratorLaurelTier.topTen;
    }

    return CuratorAccoladeLaurel(
      seasonId: json['season_id'] ?? '',
      district: json['district'] ?? '',
      rank: json['rank'] ?? 1,
      laurel: laurel,
    );
  }
}

/// Aggregated accolades profile for a curator.
class CuratorAccolades {
  final String userId;
  final String username;
  final int crownsCount;
  final List<CuratorAccoladeTrophy> trophies;
  final List<CuratorAccoladeLaurel> laurels;
  final int totalCuratorXp;
  final CuratorMasteryTier masteryTier;

  const CuratorAccolades({
    required this.userId,
    required this.username,
    required this.crownsCount,
    required this.trophies,
    required this.laurels,
    required this.totalCuratorXp,
    required this.masteryTier,
  });

  int get goldTrophiesCount =>
      trophies.where((t) => t.tier == CuratorTrophyTier.gold).length;

  int get silverTrophiesCount =>
      trophies.where((t) => t.tier == CuratorTrophyTier.silver).length;

  int get bronzeTrophiesCount =>
      trophies.where((t) => t.tier == CuratorTrophyTier.bronze).length;

  int get championLaurelsCount =>
      laurels.where((l) => l.laurel == CuratorLaurelTier.champion).length;

  int get totalAccoladeItems => crownsCount + trophies.length + laurels.length;
}

/// Evaluates accolades, computes mastery progression, and formats public share copy.
class CuratorAccoladesEngine {
  /// Determines a curator's mastery tier from crowns, gold/silver trophies, and total count.
  CuratorMasteryTier determineMasteryTier({
    required int crownsCount,
    required List<CuratorAccoladeTrophy> trophies,
  }) {
    final goldCount = trophies.where((t) => t.tier == CuratorTrophyTier.gold).length;
    final silverCount = trophies.where((t) => t.tier == CuratorTrophyTier.silver).length;
    final totalTrophies = trophies.length;

    // Grand Master: 3+ crowns OR (1+ crown AND 2+ gold trophies)
    if (crownsCount >= 3 || (crownsCount >= 1 && goldCount >= 2)) {
      return CuratorMasteryTier.grandMaster;
    }

    // Legend: 1+ crown OR 1+ gold trophy OR 2+ silver trophies
    if (crownsCount >= 1 || goldCount >= 1 || silverCount >= 2) {
      return CuratorMasteryTier.legend;
    }

    // Pioneer: 1+ silver/bronze trophy OR 3+ total trophies
    if (silverCount >= 1 || totalTrophies >= 1) {
      return CuratorMasteryTier.pioneer;
    }

    return CuratorMasteryTier.scout;
  }

  /// Builds a complete CuratorAccolades aggregate model.
  CuratorAccolades buildAccolades({
    required String userId,
    required String username,
    required int crownsCount,
    required List<CuratorAccoladeTrophy> trophies,
    required List<CuratorAccoladeLaurel> laurels,
    int totalCuratorXp = 0,
  }) {
    final tier = determineMasteryTier(
      crownsCount: crownsCount,
      trophies: trophies,
    );

    return CuratorAccolades(
      userId: userId,
      username: username,
      crownsCount: crownsCount,
      trophies: List.unmodifiable(trophies),
      laurels: List.unmodifiable(laurels),
      totalCuratorXp: totalCuratorXp,
      masteryTier: tier,
    );
  }

  /// Returns localized mastery title across UZ, RU, and EN.
  String formatMasteryTitle(CuratorMasteryTier tier, {String locale = 'en'}) {
    final lang = locale.toLowerCase();
    switch (tier) {
      case CuratorMasteryTier.grandMaster:
        if (lang.startsWith('uz')) return 'Katta Kurator Ustasi';
        if (lang.startsWith('ru')) return 'Гранд-Мастер Куратор';
        return 'Grand Master Curator';

      case CuratorMasteryTier.legend:
        if (lang.startsWith('uz')) return 'Toshkent Afsonasi';
        if (lang.startsWith('ru')) return 'Легенда Ташкента';
        return 'Tashkent Legend';

      case CuratorMasteryTier.pioneer:
        if (lang.startsWith('uz')) return 'Tuman Kashfiyotchisi';
        if (lang.startsWith('ru')) return 'Районный Первопроходец';
        return 'District Pioneer';

      case CuratorMasteryTier.scout:
        if (lang.startsWith('uz')) return 'Mahalla Qidiruvchisi';
        if (lang.startsWith('ru')) return 'Разведчик Махалли';
        return 'Neighborhood Scout';
    }
  }

  /// Formats an aesthetic social share string for Telegram, Instagram, or clipboard.
  String generateShareSummary(CuratorAccolades accolades, {String locale = 'en'}) {
    final title = formatMasteryTitle(accolades.masteryTier, locale: locale);
    final badge = accolades.masteryTier.badgeIcon;
    final lang = locale.toLowerCase();

    final sb = StringBuffer();
    sb.writeln('$badge $title — @${accolades.username}');

    if (accolades.crownsCount > 0) {
      sb.writeln('👑 ${accolades.crownsCount} District Crowns');
    }

    if (accolades.trophies.isNotEmpty) {
      sb.writeln(
        '🏆 ${accolades.trophies.length} Trophies (🥇${accolades.goldTrophiesCount} 🥈${accolades.silverTrophiesCount} 🥉${accolades.bronzeTrophiesCount})',
      );
    }

    if (accolades.laurels.isNotEmpty) {
      sb.writeln('🎖️ ${accolades.laurels.length} Seasonal Laurels');
    }

    if (lang.startsWith('uz')) {
      sb.write('Toshkent ta\'m pasportimni ko\'ring: https://around.tashkent.app/passport/${accolades.username}');
    } else if (lang.startsWith('ru')) {
      sb.write('Посмотрите мой паспорт вкуса Ташкента: https://around.tashkent.app/passport/${accolades.username}');
    } else {
      sb.write('Explore my Tashkent Taste Passport: https://around.tashkent.app/passport/${accolades.username}');
    }

    return sb.toString();
  }

  /// Calculates a weighted accolades honor score.
  int calculateAccoladesScore(CuratorAccolades accolades) {
    return (accolades.crownsCount * 1000) +
        (accolades.goldTrophiesCount * 500) +
        (accolades.silverTrophiesCount * 250) +
        (accolades.bronzeTrophiesCount * 100) +
        (accolades.laurels.length * 150) +
        (accolades.totalCuratorXp ~/ 10);
  }

  /// Computes description of requirements to unlock next tier.
  String getNextTierRequirement(CuratorAccolades accolades, {String locale = 'en'}) {
    final lang = locale.toLowerCase();
    switch (accolades.masteryTier) {
      case CuratorMasteryTier.scout:
        if (lang.startsWith('uz')) return 'Keyingi bosqich: Birinchi mavsumiy kubokni yuting';
        if (lang.startsWith('ru')) return 'Следующий ранг: Получите первый сезонный трофей';
        return 'Next Rank: Earn your first seasonal trophy';

      case CuratorMasteryTier.pioneer:
        if (lang.startsWith('uz')) return 'Keyingi bosqich: 1 ta tuman tojini yoki oltin kubokni yuting';
        if (lang.startsWith('ru')) return 'Следующий ранг: Завоюйте 1 корону района или золотой кубок';
        return 'Next Rank: Win 1 district crown or gold trophy';

      case CuratorMasteryTier.legend:
        if (lang.startsWith('uz')) return 'Keyingi bosqich: 3 ta tuman tojiga erishing';
        if (lang.startsWith('ru')) return 'Следующий ранг: Завоюйте 3 короны районов';
        return 'Next Rank: Reach 3 district crowns to become Grand Master';

      case CuratorMasteryTier.grandMaster:
        if (lang.startsWith('uz')) return 'Eng oliy daraja: Toshkent Bosh Kuratori';
        if (lang.startsWith('ru')) return 'Высший ранг: Главный Куратор Ташкента';
        return 'Highest Rank: Supreme Tashkent Curator';
    }
  }
}

final curatorAccoladesEngineProvider = Provider<CuratorAccoladesEngine>((ref) {
  return CuratorAccoladesEngine();
});
