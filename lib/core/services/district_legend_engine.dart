import '../../data/models/place_model.dart';
import '../../data/models/post_model.dart';

/// District Local Legend status awarded to the most active curator in a Tashkent neighborhood (`P15-04`).
class DistrictLegend {
  final String district;
  final String userId;
  final String userName;
  final String username;
  final int dropCount;
  final DateTime lastDropAt;
  final String badgeTitleEn;
  final String badgeTitleRu;
  final String badgeTitleUz;
  final String badgeIcon;

  const DistrictLegend({
    required this.district,
    required this.userId,
    required this.userName,
    required this.username,
    required this.dropCount,
    required this.lastDropAt,
    required this.badgeTitleEn,
    required this.badgeTitleRu,
    required this.badgeTitleUz,
    this.badgeIcon = '👑',
  });

  String getBadgeTitle(String langCode) {
    switch (langCode.toLowerCase().trim()) {
      case 'uz':
        return badgeTitleUz;
      case 'ru':
        return badgeTitleRu;
      case 'en':
      default:
        return badgeTitleEn;
    }
  }
}

/// Aggregated leaderboard containing active legends for all Tashkent districts.
class DistrictLegendLeaderboard {
  final Map<String, DistrictLegend> districtLegends;
  final Map<String, List<DistrictLegend>> userLegends;
  final int totalQualifyingDrops;

  const DistrictLegendLeaderboard({
    required this.districtLegends,
    required this.userLegends,
    required this.totalQualifyingDrops,
  });

  bool isUserLocalLegend(String userId, [String? district]) {
    final legends = userLegends[userId];
    if (legends == null || legends.isEmpty) return false;
    if (district == null) return true;
    return legends.any((l) => l.district.toLowerCase() == district.toLowerCase());
  }

  DistrictLegend? getLegendForDistrict(String district) {
    return districtLegends[district.toLowerCase()];
  }

  List<DistrictLegend> getLegendsForUser(String userId) {
    return userLegends[userId] ?? const <DistrictLegend>[];
  }
}

/// District Tastemaker & Rolling 30-Day Local Legend Engine (`P15-04`).
/// Identifies the undisputed neighborhood curator for each Tashkent district,
/// awarding cultural status and visual badge flair analogous to Strava's Local Legend.
class DistrictLegendEngine {
  /// Minimum number of verified drops within 30 days required to claim Local Legend status.
  static const int minDropsForLegend = 3;

  /// Computes the rolling 30-day leaderboard across all districts.
  static DistrictLegendLeaderboard computeLeaderboard({
    required List<PostModel> drops,
    required List<PlaceModel> places,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Map placeId and slug to district
    final placeDistrictMap = <String, String>{};
    for (final p in places) {
      placeDistrictMap[p.id] = p.district;
      placeDistrictMap[p.slug] = p.district;
    }

    // Filter drops within rolling 30-day window
    final qualifyingDrops = drops.where((d) {
      return d.createdAt.isAfter(thirtyDaysAgo) || d.createdAt.isAtSameMomentAs(thirtyDaysAgo);
    }).toList();

    // Group drops by district -> userId -> user drop stats
    // districtKey -> userId -> { count: int, latest: DateTime, name: String, username: String }
    final districtUserData = <String, Map<String, _UserDropStats>>{};

    for (final drop in qualifyingDrops) {
      final district = placeDistrictMap[drop.placeId] ?? 'Central Tashkent';
      final districtKey = district.toLowerCase();

      districtUserData.putIfAbsent(districtKey, () => <String, _UserDropStats>{});
      final userMap = districtUserData[districtKey]!;

      if (!userMap.containsKey(drop.authorId)) {
        userMap[drop.authorId] = _UserDropStats(
          userId: drop.authorId,
          userName: drop.authorName,
          username: drop.authorUsername,
          count: 1,
          lastDropAt: drop.createdAt,
          canonicalDistrict: district,
        );
      } else {
        final existing = userMap[drop.authorId]!;
        final latest = drop.createdAt.isAfter(existing.lastDropAt) ? drop.createdAt : existing.lastDropAt;
        userMap[drop.authorId] = _UserDropStats(
          userId: existing.userId,
          userName: drop.authorName.isNotEmpty ? drop.authorName : existing.userName,
          username: drop.authorUsername.isNotEmpty ? drop.authorUsername : existing.username,
          count: existing.count + 1,
          lastDropAt: latest,
          canonicalDistrict: existing.canonicalDistrict,
        );
      }
    }

    final districtLegends = <String, DistrictLegend>{};
    final userLegends = <String, List<DistrictLegend>>{};

    // For each district, find the user with the highest drop count >= minDropsForLegend
    for (final entry in districtUserData.entries) {
      final districtKey = entry.key;
      final candidates = entry.value.values.where((c) => c.count >= minDropsForLegend).toList();

      if (candidates.isEmpty) continue;

      // Sort by drop count descending; on tie, most recent drop wins; on tie, alphabetical
      candidates.sort((a, b) {
        final cmp = b.count.compareTo(a.count);
        if (cmp != 0) return cmp;
        final timeCmp = b.lastDropAt.compareTo(a.lastDropAt);
        if (timeCmp != 0) return timeCmp;
        return a.username.compareTo(b.username);
      });

      final winner = candidates.first;
      final canonicalDistrict = winner.canonicalDistrict;
      final uzbekDistrict = _toUzbekDistrict(canonicalDistrict);

      final legend = DistrictLegend(
        district: canonicalDistrict,
        userId: winner.userId,
        userName: winner.userName,
        username: winner.username,
        dropCount: winner.count,
        lastDropAt: winner.lastDropAt,
        badgeTitleEn: '$canonicalDistrict Local Legend',
        badgeTitleRu: 'Легенда района $canonicalDistrict',
        badgeTitleUz: '$uzbekDistrict Afsonasi',
      );

      districtLegends[districtKey] = legend;
      userLegends.putIfAbsent(winner.userId, () => <DistrictLegend>[]).add(legend);
    }

    return DistrictLegendLeaderboard(
      districtLegends: districtLegends,
      userLegends: userLegends,
      totalQualifyingDrops: qualifyingDrops.length,
    );
  }

  static String _toUzbekDistrict(String district) {
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
}

class _UserDropStats {
  final String userId;
  final String userName;
  final String username;
  final int count;
  final DateTime lastDropAt;
  final String canonicalDistrict;

  const _UserDropStats({
    required this.userId,
    required this.userName,
    required this.username,
    required this.count,
    required this.lastDropAt,
    required this.canonicalDistrict,
  });
}
