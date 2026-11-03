import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/place_model.dart';
import '../../data/models/post_model.dart';

/// Temporal proximity tier for privacy-preserving ambient presence (`P16-04`).
enum FriendPresenceRecency {
  justNow,      // < 30 minutes
  recentHours,  // < 4 hours
  earlierToday, // < 12 hours
  yesterday,    // 12 - 24 hours
  inactive,     // > 24 hours or no recorded drops
}

/// Ambient friend presence status revealing neighbourhood activity without raw GPS leakage.
class FriendPresenceStatus {
  final String userId;
  final String? district;
  final DateTime? lastActiveAt;
  final FriendPresenceRecency recency;

  const FriendPresenceStatus({
    required this.userId,
    this.district,
    this.lastActiveAt,
    required this.recency,
  });

  /// High-confidence online indicator (< 30 minutes).
  bool get isOnline => recency == FriendPresenceRecency.justNow;

  /// Whether friend was active within the rolling 24-hour cycle.
  bool get isRecent => recency != FriendPresenceRecency.inactive;

  /// Localized privacy-preserving status string across Uzbek, Russian, and English.
  String getLocalizedLabel(String langCode, {DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    final lang = langCode.toLowerCase().trim();

    final hours = lastActiveAt != null
        ? now.difference(lastActiveAt!).inHours.clamp(1, 23)
        : 1;

    switch (lang) {
      case 'uz':
        final uzDistrict = district != null ? _toUzbekDistrict(district!) : null;
        switch (recency) {
          case FriendPresenceRecency.justNow:
            return uzDistrict != null
                ? '${uzDistrict}da faol • Hozirgina'
                : 'Faol • Hozirgina';
          case FriendPresenceRecency.recentHours:
            return uzDistrict != null
                ? '${uzDistrict}da faol • $hours soat oldin'
                : 'Faol • $hours soat oldin';
          case FriendPresenceRecency.earlierToday:
            return uzDistrict != null
                ? '${uzDistrict}da faol • Bugun erta'
                : 'Faol • Bugun erta';
          case FriendPresenceRecency.yesterday:
            return uzDistrict != null
                ? '${uzDistrict}da faol • Kecha'
                : 'Kecha faol';
          case FriendPresenceRecency.inactive:
            return 'Dam olmoqda';
        }

      case 'ru':
        switch (recency) {
          case FriendPresenceRecency.justNow:
            return district != null
                ? 'Активен в $district • Только что'
                : 'Активен • Только что';
          case FriendPresenceRecency.recentHours:
            return district != null
                ? 'Активен в $district • $hours ч назад'
                : 'Активен • $hours ч назад';
          case FriendPresenceRecency.earlierToday:
            return district != null
                ? 'Активен в $district • Ранее сегодня'
                : 'Активен • Ранее сегодня';
          case FriendPresenceRecency.yesterday:
            return district != null
                ? 'Активен в $district • Вчера'
                : 'Был в сети вчера';
          case FriendPresenceRecency.inactive:
            return 'Не в сети';
        }

      case 'en':
      default:
        switch (recency) {
          case FriendPresenceRecency.justNow:
            return district != null
                ? 'Active in $district • Just now'
                : 'Active • Just now';
          case FriendPresenceRecency.recentHours:
            return district != null
                ? 'Active in $district • ${hours}h ago'
                : 'Active • ${hours}h ago';
          case FriendPresenceRecency.earlierToday:
            return district != null
                ? 'Active in $district • Earlier today'
                : 'Active • Earlier today';
          case FriendPresenceRecency.yesterday:
            return district != null
                ? 'Active in $district • Yesterday'
                : 'Active • Yesterday';
          case FriendPresenceRecency.inactive:
            return 'Resting';
        }
    }
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

/// Ambient Friend Presence & Neighborhood Rhythm Indicator Engine (`P16-04`).
/// Aggregates friend drops into ambient neighbourhood status cards, preventing
/// direct GPS coordinate exposure while fostering spontaneous urban meetups.
class FriendPresenceEngine {
  /// Computes privacy-preserving presence status for a single user.
  static FriendPresenceStatus computeStatus({
    required String userId,
    required List<PostModel> drops,
    List<PlaceModel> places = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();

    // Map placeId and slug to canonical district
    final placeDistrictMap = <String, String>{};
    for (final p in places) {
      placeDistrictMap[p.id] = p.district;
      placeDistrictMap[p.slug] = p.district;
    }

    // Filter drops created by this user
    final userDrops = drops.where((d) => d.authorId == userId).toList();
    if (userDrops.isEmpty) {
      return FriendPresenceStatus(
        userId: userId,
        recency: FriendPresenceRecency.inactive,
      );
    }

    // Sort descending by creation timestamp
    userDrops.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestDrop = userDrops.first;
    final diff = now.difference(latestDrop.createdAt);

    if (diff.isNegative) {
      // Clock skew edge case: future timestamp treated as just now
      final district = placeDistrictMap[latestDrop.placeId] ?? _inferDistrict(latestDrop);
      return FriendPresenceStatus(
        userId: userId,
        district: district,
        lastActiveAt: latestDrop.createdAt,
        recency: FriendPresenceRecency.justNow,
      );
    }

    if (diff.inMinutes < 30) {
      final district = placeDistrictMap[latestDrop.placeId] ?? _inferDistrict(latestDrop);
      return FriendPresenceStatus(
        userId: userId,
        district: district,
        lastActiveAt: latestDrop.createdAt,
        recency: FriendPresenceRecency.justNow,
      );
    }

    if (diff.inHours < 4) {
      final district = placeDistrictMap[latestDrop.placeId] ?? _inferDistrict(latestDrop);
      return FriendPresenceStatus(
        userId: userId,
        district: district,
        lastActiveAt: latestDrop.createdAt,
        recency: FriendPresenceRecency.recentHours,
      );
    }

    if (diff.inHours < 12) {
      final district = placeDistrictMap[latestDrop.placeId] ?? _inferDistrict(latestDrop);
      return FriendPresenceStatus(
        userId: userId,
        district: district,
        lastActiveAt: latestDrop.createdAt,
        recency: FriendPresenceRecency.earlierToday,
      );
    }

    if (diff.inHours < 24) {
      final district = placeDistrictMap[latestDrop.placeId] ?? _inferDistrict(latestDrop);
      return FriendPresenceStatus(
        userId: userId,
        district: district,
        lastActiveAt: latestDrop.createdAt,
        recency: FriendPresenceRecency.yesterday,
      );
    }

    return FriendPresenceStatus(
      userId: userId,
      district: null,
      lastActiveAt: latestDrop.createdAt,
      recency: FriendPresenceRecency.inactive,
    );
  }

  /// Computes ambient status for a list of friends.
  static Map<String, FriendPresenceStatus> computeAllStatuses({
    required List<String> friendIds,
    required List<PostModel> drops,
    List<PlaceModel> places = const [],
    DateTime? referenceTime,
  }) {
    final result = <String, FriendPresenceStatus>{};
    for (final id in friendIds) {
      result[id] = computeStatus(
        userId: id,
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );
    }
    return result;
  }

  /// Aggregates distinct active friends per Tashkent district over the last 24 hours.
  static Map<String, int> getNeighborhoodFriendCounts({
    required List<String> friendIds,
    required List<PostModel> drops,
    List<PlaceModel> places = const [],
    DateTime? referenceTime,
  }) {
    final statuses = computeAllStatuses(
      friendIds: friendIds,
      drops: drops,
      places: places,
      referenceTime: referenceTime,
    );

    final counts = <String, int>{};
    for (final status in statuses.values) {
      if (status.isRecent && status.district != null) {
        final d = status.district!;
        counts[d] = (counts[d] ?? 0) + 1;
      }
    }

    return counts;
  }

  static String? _inferDistrict(PostModel drop) {
    final addr = drop.placeAddress.toLowerCase();
    if (addr.contains('mirabad') || addr.contains('mirobod')) return 'Mirabad';
    if (addr.contains('yunusabad') || addr.contains('yunusobod')) return 'Yunusabad';
    if (addr.contains('yakkasaray') || addr.contains('yakkasaroy')) return 'Yakkasaray';
    if (addr.contains('shaykhontohur') || addr.contains('shayxontohur')) return 'Shaykhontohur';
    if (addr.contains('chilanzar') || addr.contains('chilonzor')) return 'Chilanzar';
    return null;
  }
}

/// Global Riverpod provider for ambient friend presence engine.
final friendPresenceEngineProvider = Provider<FriendPresenceEngine>((ref) => FriendPresenceEngine());
