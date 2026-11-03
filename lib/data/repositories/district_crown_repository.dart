import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/district_crown_leaderboard_engine.dart';
import '../services/supabase_service.dart';

/// Repository for retrieving real-time Tashkent district crown leaderboards and rivalries.
class DistrictCrownRepository {
  final DistrictCrownLeaderboardEngine _engine;

  DistrictCrownRepository({DistrictCrownLeaderboardEngine? engine})
      : _engine = engine ?? DistrictCrownLeaderboardEngine();

  /// Fetches the district crown podium and rankings for a given district and season.
  /// Seamlessly falls back to local seed standings if offline or Supabase is uninitialized.
  Future<DistrictCrownPodium> getDistrictCrownPodium({
    required String district,
    String? seasonId,
  }) async {
    final activeSeason = seasonId ?? _currentSeasonId();

    if (!SupabaseService.isInitialized) {
      return _buildOfflineFallback(district, activeSeason);
    }

    try {
      final res = await SupabaseService.client.rpc(
        'get_district_crown_standings',
        params: {
          'p_district': district,
          if (seasonId != null) 'p_season_id': seasonId,
        },
      );

      if (res is Map<String, dynamic> && res['success'] == true) {
        final rawStandings = res['standings'] as List? ?? [];
        final parsedCurators = <DistrictCuratorStanding>[];

        for (final item in rawStandings) {
          if (item is Map<String, dynamic>) {
            parsedCurators.add(DistrictCuratorStanding.fromJson(item));
          }
        }

        return _engine.computePodium(
          rawStandings: parsedCurators,
          district: district,
          seasonId: activeSeason,
        );
      }

      return _buildOfflineFallback(district, activeSeason);
    } catch (e) {
      AppLogger.warn(
        'DistrictCrownRepository',
        'Failed to fetch district crown standings via RPC, using offline fallback',
        e,
      );
      return _buildOfflineFallback(district, activeSeason);
    }
  }

  String _currentSeasonId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  DistrictCrownPodium _buildOfflineFallback(String district, String seasonId) {
    // Curated offline seed curators for authentic Tashkent district rivalries
    final seedCurators = <DistrictCuratorStanding>[
      DistrictCuratorStanding(
        userId: 'seed-champ-1',
        username: '@jasur_brew',
        fullName: 'Jasur Aliyev',
        district: district,
        rank: 1,
        seasonXp: 1420,
        placesCount: 9,
        crownsCount: 2,
        gapToLeaderXp: 0,
        gapToNextRankXp: 0,
      ),
      DistrictCuratorStanding(
        userId: 'seed-silver-2',
        username: '@kamila_tashkent',
        fullName: 'Kamila Karimova',
        district: district,
        rank: 2,
        seasonXp: 1180,
        placesCount: 7,
        crownsCount: 1,
        gapToLeaderXp: 240,
        gapToNextRankXp: 250,
      ),
      DistrictCuratorStanding(
        userId: 'seed-bronze-3',
        username: '@nodir_walks',
        fullName: 'Nodir Usmanov',
        district: district,
        rank: 3,
        seasonXp: 860,
        placesCount: 5,
        crownsCount: 0,
        gapToLeaderXp: 560,
        gapToNextRankXp: 330,
      ),
      DistrictCuratorStanding(
        userId: 'seed-runner-4',
        username: '@diana_art',
        fullName: 'Diana Lee',
        district: district,
        rank: 4,
        seasonXp: 640,
        placesCount: 4,
        crownsCount: 0,
        gapToLeaderXp: 780,
        gapToNextRankXp: 230,
      ),
    ];

    return _engine.computePodium(
      rawStandings: seedCurators,
      district: district,
      seasonId: seasonId,
    );
  }
}

final districtCrownRepositoryProvider = Provider<DistrictCrownRepository>((ref) {
  final engine = ref.watch(districtCrownLeaderboardEngineProvider);
  return DistrictCrownRepository(engine: engine);
});

final districtCrownPodiumProvider =
    FutureProvider.family<DistrictCrownPodium, String>((ref, district) async {
  final repo = ref.watch(districtCrownRepositoryProvider);
  return repo.getDistrictCrownPodium(district: district);
});
