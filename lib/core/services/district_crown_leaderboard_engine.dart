import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A curator's ranked standing in a specific Tashkent district.
class DistrictCuratorStanding {
  final String userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final int rank;
  final String district;
  final int seasonXp;
  final int placesCount;
  final int crownsCount;
  final int gapToLeaderXp;
  final int gapToNextRankXp;

  const DistrictCuratorStanding({
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.rank,
    required this.district,
    required this.seasonXp,
    required this.placesCount,
    required this.crownsCount,
    this.gapToLeaderXp = 0,
    this.gapToNextRankXp = 0,
  });

  bool get isReigningChampion => rank == 1;
  bool get isPodium => rank >= 1 && rank <= 3;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'CR';
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'rank': rank,
    'district': district,
    'season_xp': seasonXp,
    'places_count': placesCount,
    'crowns_count': crownsCount,
    'gap_to_leader_xp': gapToLeaderXp,
    'gap_to_next_rank_xp': gapToNextRankXp,
  };

  factory DistrictCuratorStanding.fromJson(Map<String, dynamic> json) {
    return DistrictCuratorStanding(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      rank: json['rank'] ?? 1,
      district: json['district'] ?? 'Mirabad',
      seasonXp: json['season_xp'] ?? 0,
      placesCount: json['places_count'] ?? 0,
      crownsCount: json['crowns_count'] ?? 0,
      gapToLeaderXp: json['gap_to_leader_xp'] ?? 0,
      gapToNextRankXp: json['gap_to_next_rank_xp'] ?? 0,
    );
  }
}

/// The top 3 podium contenders and runner-up curators for a district.
class DistrictCrownPodium {
  final String district;
  final String seasonId;
  final DistrictCuratorStanding? champion;
  final DistrictCuratorStanding? silver;
  final DistrictCuratorStanding? bronze;
  final List<DistrictCuratorStanding> runnersUp;
  final int totalCuratorsCount;

  const DistrictCrownPodium({
    required this.district,
    required this.seasonId,
    this.champion,
    this.silver,
    this.bronze,
    this.runnersUp = const [],
    required this.totalCuratorsCount,
  });

  List<DistrictCuratorStanding> get allRanked {
    final list = <DistrictCuratorStanding>[];
    if (champion != null) list.add(champion!);
    if (silver != null) list.add(silver!);
    if (bronze != null) list.add(bronze!);
    list.addAll(runnersUp);
    return list;
  }
}

/// Computes district rankings, assigns podium placements, and calculates gap-to-crown metrics.
class DistrictCrownLeaderboardEngine {
  /// Sorts and calculates podium placements for a district from raw curator scores.
  DistrictCrownPodium computePodium({
    required List<DistrictCuratorStanding> rawStandings,
    required String district,
    required String seasonId,
  }) {
    if (rawStandings.isEmpty) {
      return DistrictCrownPodium(
        district: district,
        seasonId: seasonId,
        totalCuratorsCount: 0,
      );
    }

    // Sort by: crownsCount DESC, seasonXp DESC, placesCount DESC
    final sorted = List<DistrictCuratorStanding>.from(rawStandings)
      ..sort((a, b) {
        if (b.crownsCount != a.crownsCount) {
          return b.crownsCount.compareTo(a.crownsCount);
        }
        if (b.seasonXp != a.seasonXp) {
          return b.seasonXp.compareTo(a.seasonXp);
        }
        return b.placesCount.compareTo(a.placesCount);
      });

    final rankedList = <DistrictCuratorStanding>[];
    final leaderXp = sorted.first.seasonXp;

    for (var i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final rank = i + 1;
      final gapToLeader = (leaderXp - current.seasonXp).clamp(0, 999999);
      final gapToNext = i > 0 ? (sorted[i - 1].seasonXp - current.seasonXp + 10).clamp(0, 999999) : 0;

      rankedList.add(DistrictCuratorStanding(
        userId: current.userId,
        username: current.username,
        fullName: current.fullName,
        avatarUrl: current.avatarUrl,
        rank: rank,
        district: district,
        seasonXp: current.seasonXp,
        placesCount: current.placesCount,
        crownsCount: current.crownsCount,
        gapToLeaderXp: gapToLeader,
        gapToNextRankXp: gapToNext,
      ));
    }

    final champion = rankedList.isNotEmpty ? rankedList[0] : null;
    final silver = rankedList.length > 1 ? rankedList[1] : null;
    final bronze = rankedList.length > 2 ? rankedList[2] : null;
    final runnersUp = rankedList.length > 3 ? rankedList.sublist(3) : <DistrictCuratorStanding>[];

    return DistrictCrownPodium(
      district: district,
      seasonId: seasonId,
      champion: champion,
      silver: silver,
      bronze: bronze,
      runnersUp: runnersUp,
      totalCuratorsCount: rankedList.length,
    );
  }

  /// Formats district title localized in Uzbek, Russian, or English.
  String formatDistrictTitle(String district, {String locale = 'en'}) {
    final lang = locale.toLowerCase();
    final cleanDistrict = district.trim();

    if (lang.startsWith('uz')) {
      return '$cleanDistrict tumani';
    } else if (lang.startsWith('ru')) {
      return '$cleanDistrict район';
    }
    return '$cleanDistrict District';
  }

  /// Formats rank label with crown / laurel emojis.
  String formatCuratorRankLabel(int rank, {String locale = 'en'}) {
    final lang = locale.toLowerCase();
    switch (rank) {
      case 1:
        if (lang.startsWith('uz')) return '👑 Chempion Toji';
        if (lang.startsWith('ru')) return '👑 Корона Чемпиона';
        return '👑 Champion Crown';

      case 2:
        if (lang.startsWith('uz')) return '🥈 Kumush Shon-Sharaf';
        if (lang.startsWith('ru')) return '🥈 Серебряный Лавр';
        return '🥈 Silver Laurel';

      case 3:
        if (lang.startsWith('uz')) return '🥉 Bronza Shon-Sharaf';
        if (lang.startsWith('ru')) return '🥉 Бронзовый Лавр';
        return '🥉 Bronze Laurel';

      default:
        return '#$rank';
    }
  }
}

final districtCrownLeaderboardEngineProvider = Provider<DistrictCrownLeaderboardEngine>((ref) {
  return DistrictCrownLeaderboardEngine();
});
