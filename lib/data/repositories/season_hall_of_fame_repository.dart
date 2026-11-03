import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/season_ceremony_engine.dart';
import '../services/supabase_service.dart';

class SeasonHallOfFameRepository {
  /// Archives a curator's seasonal standing via Supabase RPC.
  /// Falls back gracefully when offline or unauthenticated.
  Future<Map<String, dynamic>> archiveSeasonStanding({
    required String seasonId,
    required String district,
    required int rank,
    required int seasonXp,
    int placesCount = 0,
    CuratorLaurelTier laurel = CuratorLaurelTier.explorer,
  }) async {
    final cleanSeason = seasonId.trim();
    if (cleanSeason.isEmpty) {
      return {'success': false, 'error': 'Season ID cannot be empty'};
    }

    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      // Local fallback for offline simulation or testing
      return {
        'success': true,
        'offline': true,
        'season_id': cleanSeason,
        'district': district.trim(),
        'rank': rank,
        'season_xp': seasonXp,
        'places_count': placesCount,
        'laurel': laurel.name,
      };
    }

    try {
      final res = await SupabaseService.client.rpc(
        'archive_season_standing',
        params: {
          'p_season_id': cleanSeason,
          'p_district': district.trim(),
          'p_rank': rank,
          'p_season_xp': seasonXp,
          'p_places_count': placesCount,
          'p_laurel': laurel.name,
        },
      );

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true, 'data': res};
    } catch (e) {
      AppLogger.warn('SeasonHallOfFameRepository', 'archiveSeasonStanding RPC failed, falling back', e);
      return {
        'success': false,
        'error': e.toString(),
        'season_id': cleanSeason,
      };
    }
  }

  /// Fetches historical Hall of Fame records across seasons and districts.
  Future<List<Map<String, dynamic>>> getHallOfFameEntries({
    String? seasonId,
    String? district,
    int limit = 50,
  }) async {
    if (!SupabaseService.isInitialized) {
      return [];
    }

    try {
      var query = SupabaseService.client
          .from('season_hall_of_fame')
          .select('*, profiles(username, full_name, avatar_url)');

      if (seasonId != null && seasonId.trim().isNotEmpty) {
        query = query.eq('season_id', seasonId.trim());
      }

      if (district != null && district.trim().isNotEmpty && district.toLowerCase() != 'all') {
        query = query.eq('district', district.trim());
      }

      final res = await query.order('rank', ascending: true).limit(limit);

      final entries = <Map<String, dynamic>>[];
      for (final row in res) {
        entries.add(Map<String, dynamic>.from(row));
      }
      return entries;
    } catch (e) {
      AppLogger.warn('SeasonHallOfFameRepository', 'Failed to fetch Hall of Fame entries', e);
      return [];
    }
  }
}

final seasonHallOfFameRepositoryProvider = Provider<SeasonHallOfFameRepository>((ref) {
  return SeasonHallOfFameRepository();
});

final hallOfFameEntriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(seasonHallOfFameRepositoryProvider);
  return repo.getHallOfFameEntries();
});
