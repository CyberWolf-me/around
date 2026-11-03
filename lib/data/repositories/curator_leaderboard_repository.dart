import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../services/supabase_service.dart';
import 'profiles_repository.dart';

class CuratorLeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final int curatorXp;
  final int curatorLevel;
  final String curatorTier;
  final int districtDropsCount;

  const CuratorLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.curatorXp,
    required this.curatorLevel,
    required this.curatorTier,
    required this.districtDropsCount,
  });

  factory CuratorLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return CuratorLeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      curatorXp: (json['curator_xp'] as num?)?.toInt() ?? 0,
      curatorLevel: (json['curator_level'] as num?)?.toInt() ?? 1,
      curatorTier: json['curator_tier']?.toString() ?? 'neighborhoodScout',
      districtDropsCount: (json['district_drops_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'user_id': userId,
    'username': username,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'curator_xp': curatorXp,
    'curator_level': curatorLevel,
    'curator_tier': curatorTier,
    'district_drops_count': districtDropsCount,
  };
}

class CuratorLeaderboardRepository {
  Future<List<CuratorLeaderboardEntry>> getCuratorLeaderboard({
    String? district,
    int limit = 20,
  }) async {
    if (SupabaseService.isInitialized) {
      try {
        final params = <String, dynamic>{
          'p_limit': limit,
        };
        if (district != null && district.trim().isNotEmpty) {
          params['p_district'] = district.trim();
        }

        final res = await SupabaseService.client.rpc('get_curator_leaderboard', params: params);
        if (res is List) {
          return res
              .whereType<Map<String, dynamic>>()
              .map(CuratorLeaderboardEntry.fromJson)
              .toList();
        }
      } catch (e) {
        AppLogger.warn('CuratorLeaderboardRepository', 'Supabase RPC call failed, using mock data', e);
      }
    }

    // High fidelity fallback ranking from Tashkent community members
    final members = List<CommunityMember>.from(kTashkentCommunityMembers);
    if (district != null && district.trim().isNotEmpty) {
      members.retainWhere((m) => m.neighborhood.toLowerCase() == district.trim().toLowerCase());
    }

    members.sort((a, b) => b.dropsCount.compareTo(a.dropsCount));

    return members.take(limit).toList().asMap().entries.map((entry) {
      final idx = entry.key;
      final m = entry.value;
      final xp = m.dropsCount * 50;
      final tier = xp >= 2000
          ? 'tashkentLegend'
          : xp >= 750
              ? 'cityPioneer'
              : xp >= 250
                  ? 'districtCurator'
                  : 'neighborhoodScout';
      final level = xp >= 2000
          ? 4
          : xp >= 750
              ? 3
              : xp >= 250
                  ? 2
                  : 1;

      return CuratorLeaderboardEntry(
        rank: idx + 1,
        userId: m.id,
        username: m.handle,
        fullName: m.name,
        curatorXp: xp,
        curatorLevel: level,
        curatorTier: tier,
        districtDropsCount: m.dropsCount,
      );
    }).toList();
  }

  Future<Map<String, dynamic>?> syncCuratorXp({String? targetId}) async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) {
      return null;
    }

    try {
      final res = await SupabaseService.client.rpc('sync_profile_curator_xp', params: {
        if (targetId != null) 'p_target_id': targetId,
      });
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      AppLogger.warn('CuratorLeaderboardRepository', 'syncCuratorXp RPC failed', e);
    }
    return null;
  }
}

final curatorLeaderboardRepositoryProvider = Provider<CuratorLeaderboardRepository>((ref) {
  return CuratorLeaderboardRepository();
});

final curatorLeaderboardFamilyProvider = FutureProvider.family<List<CuratorLeaderboardEntry>, String?>((ref, district) async {
  final repo = ref.watch(curatorLeaderboardRepositoryProvider);
  return repo.getCuratorLeaderboard(district: district);
});
