import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/curated_route_engine.dart';
import '../services/supabase_service.dart';

class CuratedRouteRepository {
  Future<List<CuratedRoute>> getCuratedRoutes() async {
    if (SupabaseService.isInitialized) {
      try {
        final res = await SupabaseService.client
            .from('curated_routes')
            .select('*')
            .order('district', ascending: true);

        if (res.isNotEmpty) {
          final routes = <CuratedRoute>[];
          for (final row in res) {
            final map = Map<String, dynamic>.from(row);
            final rawStops = map['stops'];
            final stops = <RouteStop>[];

            if (rawStops is List) {
              for (int i = 0; i < rawStops.length; i++) {
                final s = Map<String, dynamic>.from(rawStops[i]);
                stops.add(RouteStop(
                  placeId: s['place_id']?.toString() ?? '',
                  name: s['name']?.toString() ?? '',
                  district: map['district']?.toString() ?? '',
                  latitude: (s['latitude'] as num?)?.toDouble() ?? 41.31,
                  longitude: (s['longitude'] as num?)?.toDouble() ?? 69.28,
                  recommendedOrder: i + 1,
                  atmosphereTag: s['atmosphere_tag']?.toString() ?? '',
                  nearestSubway: s['nearest_subway']?.toString() ?? '',
                  walkingMinutesFromPrevious: (s['walking_minutes_from_previous'] as num?)?.toInt() ?? 0,
                ));
              }
            }

            routes.add(CuratedRoute(
              id: map['id']?.toString() ?? '',
              title: map['title']?.toString() ?? '',
              subtitle: map['subtitle']?.toString() ?? '',
              district: map['district']?.toString() ?? '',
              emoji: map['emoji']?.toString() ?? '📍',
              stops: stops,
              totalEstimatedMinutes: (map['total_estimated_minutes'] as num?)?.toInt() ?? 15,
              totalDistanceMeters: (map['total_distance_meters'] as num?)?.toInt() ?? 1000,
              xpReward: (map['xp_reward'] as num?)?.toInt() ?? 150,
              startSubway: map['start_subway']?.toString() ?? '',
              endSubway: map['end_subway']?.toString() ?? '',
            ));
          }
          if (routes.isNotEmpty) return routes;
        }
      } catch (e) {
        AppLogger.warn('CuratedRouteRepository', 'Failed to fetch remote curated routes, using fallback', e);
      }
    }
    return CuratedRouteEngine.getAllRoutes();
  }

  Future<Set<String>> getCompletedRouteIds({String? userId}) async {
    final targetUid = userId ?? SupabaseService.currentUser?.id;
    if (targetUid == null || !SupabaseService.isInitialized) {
      return {};
    }

    try {
      final res = await SupabaseService.client
          .from('route_completions')
          .select('route_id')
          .eq('user_id', targetUid);

      return res
          .whereType<Map<String, dynamic>>()
          .map((r) => r['route_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      AppLogger.warn('CuratedRouteRepository', 'Failed to fetch completed routes', e);
    }
    return {};
  }

  Future<Map<String, dynamic>?> completeRoute(String routeId) async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) {
      return null;
    }

    try {
      final res = await SupabaseService.client.rpc('complete_curated_route', params: {
        'p_route_id': routeId,
      });
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      AppLogger.warn('CuratedRouteRepository', 'completeRoute RPC failed', e);
    }
    return null;
  }
}

final curatedRouteRepositoryProvider = Provider<CuratedRouteRepository>((ref) {
  return CuratedRouteRepository();
});

final completedRoutesProvider = FutureProvider.family<Set<String>, String?>((ref, userId) async {
  final repo = ref.watch(curatedRouteRepositoryProvider);
  return repo.getCompletedRouteIds(userId: userId);
});
