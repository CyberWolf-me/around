import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/season_trophy_engine.dart';
import '../services/supabase_service.dart';

class SeasonTrophyRepository {
  /// Claims a seasonal trophy and persists bonus XP via Supabase RPC.
  /// Falls back gracefully when offline or unauthenticated.
  Future<Map<String, dynamic>> claimSeasonalTrophy({
    required String seasonId,
    required String seasonTitle,
    required CuratorTrophyTier tier,
    required int completedChallengesCount,
    int xpBonus = 100,
  }) async {
    final cleanSeasonId = seasonId.trim();
    if (cleanSeasonId.isEmpty) {
      return {'success': false, 'error': 'Season ID cannot be empty'};
    }

    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      // Local fallback for offline simulation or testing
      return {
        'success': true,
        'offline': true,
        'already_claimed': false,
        'season_id': cleanSeasonId,
        'season_title': seasonTitle,
        'trophy_tier': tier.id,
        'xp_awarded': xpBonus,
        'total_xp': xpBonus,
        'curator_level': 1,
        'curator_tier': 'neighborhoodScout',
      };
    }

    try {
      final res = await SupabaseService.client.rpc(
        'claim_seasonal_trophy',
        params: {
          'p_season_id': cleanSeasonId,
          'p_season_title': seasonTitle.trim(),
          'p_trophy_tier': tier.id,
          'p_completed_challenges_count': completedChallengesCount,
          'p_xp_bonus': xpBonus,
        },
      );

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true, 'data': res};
    } catch (e) {
      AppLogger.warn('SeasonTrophyRepository', 'claimSeasonalTrophy RPC call failed, falling back', e);
      return {
        'success': false,
        'error': e.toString(),
        'season_id': cleanSeasonId,
      };
    }
  }

  /// Fetches claimed seasonal trophies for the authenticated user.
  Future<List<Map<String, dynamic>>> getClaimedTrophies({String? userId}) async {
    final targetUid = userId ?? SupabaseService.currentUser?.id;
    if (targetUid == null || !SupabaseService.isInitialized) {
      return [];
    }

    try {
      final res = await SupabaseService.client
          .from('seasonal_trophies')
          .select('*')
          .eq('user_id', targetUid)
          .order('claimed_at', ascending: false);

      final trophies = <Map<String, dynamic>>[];
      for (final row in res) {
        trophies.add(Map<String, dynamic>.from(row));
      }
      return trophies;
    } catch (e) {
      AppLogger.warn('SeasonTrophyRepository', 'Failed to fetch claimed seasonal trophies', e);
      return [];
    }
  }
}

final seasonTrophyRepositoryProvider = Provider<SeasonTrophyRepository>((ref) {
  return SeasonTrophyRepository();
});

final claimedTrophiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(seasonTrophyRepositoryProvider);
  return repo.getClaimedTrophies();
});
