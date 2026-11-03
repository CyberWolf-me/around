import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/curated_walk_waypoint_engine.dart';
import '../services/supabase_service.dart';

/// Repository for tracking curated walk checkpoint progression across Tashkent trails.
class CuratedWalkWaypointRepository {
  final CuratedWalkWaypointEngine _engine;
  final Set<String> _offlineVisitedPlaceIds = {};

  CuratedWalkWaypointRepository({CuratedWalkWaypointEngine? engine})
      : _engine = engine ?? CuratedWalkWaypointEngine();

  /// Evaluates route progress for a user, combining persistent database state or local cache.
  Future<RouteProgressSummary> getRouteProgress({
    required String routeId,
    required String routeName,
    required String district,
    required List<RouteWaypoint> waypoints,
    int completionBonusXp = 50,
  }) async {
    final callerId = SupabaseService.currentUser?.id;

    if (!SupabaseService.isInitialized || callerId == null) {
      return _engine.evaluateProgress(
        routeId: routeId,
        routeName: routeName,
        district: district,
        waypoints: waypoints,
        visitedPlaceIds: _offlineVisitedPlaceIds,
        completionBonusXp: completionBonusXp,
      );
    }

    try {
      final res = await SupabaseService.client
          .from('route_waypoint_checkins')
          .select('place_id')
          .eq('user_id', callerId)
          .eq('route_id', routeId);

      final visitedPlaceIds = <String>{};
      for (final row in res) {
        if (row['place_id'] != null) {
          visitedPlaceIds.add(row['place_id'].toString());
        }
      }

      return _engine.evaluateProgress(
        routeId: routeId,
        routeName: routeName,
        district: district,
        waypoints: waypoints,
        visitedPlaceIds: visitedPlaceIds,
        completionBonusXp: completionBonusXp,
      );
    } catch (e) {
      AppLogger.warn(
        'CuratedWalkWaypointRepository',
        'Failed to query route waypoint checkins, falling back to local state',
        e,
      );
      return _engine.evaluateProgress(
        routeId: routeId,
        routeName: routeName,
        district: district,
        waypoints: waypoints,
        visitedPlaceIds: _offlineVisitedPlaceIds,
        completionBonusXp: completionBonusXp,
      );
    }
  }

  /// Records a checkpoint check-in for the current user.
  Future<bool> recordWaypointCheckin({
    required String routeId,
    required String placeId,
    int baseXp = 15,
    int bonusXp = 50,
  }) async {
    // Record in local cache
    _offlineVisitedPlaceIds.add(placeId);

    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      return true;
    }

    try {
      final res = await SupabaseService.client.rpc(
        'record_route_waypoint_progress',
        params: {
          'p_route_id': routeId,
          'p_place_id': placeId,
          'p_base_xp': baseXp,
          'p_completion_bonus_xp': bonusXp,
        },
      );

      if (res is Map && res['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.warn(
        'CuratedWalkWaypointRepository',
        'Failed to record waypoint check-in via RPC, cached locally',
        e,
      );
      return true;
    }
  }

  /// Clears offline visited check-ins (useful for testing).
  void clearOfflineCache() {
    _offlineVisitedPlaceIds.clear();
  }
}

final curatedWalkWaypointRepositoryProvider =
    Provider<CuratedWalkWaypointRepository>((ref) {
  final engine = ref.watch(curatedWalkWaypointEngineProvider);
  return CuratedWalkWaypointRepository(engine: engine);
});
