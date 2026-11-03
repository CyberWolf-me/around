import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/district_activity_ticker_engine.dart';
import '../services/supabase_service.dart';

/// Repository for streaming ambient community pulses across Tashkent districts.
class DistrictActivityRepository {
  final DistrictActivityTickerEngine _engine;

  DistrictActivityRepository({DistrictActivityTickerEngine? engine})
      : _engine = engine ?? DistrictActivityTickerEngine();

  /// Fetches recent sanitized activity events, gracefully falling back to local seeds if offline.
  Future<List<DistrictActivityEvent>> getDistrictActivityEvents({
    String? district,
    int limit = 20,
  }) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineFallback(district);
    }

    try {
      final res = await SupabaseService.client.rpc(
        'get_district_activity_ticker',
        params: {
          if (district != null) 'p_district': district,
          'p_limit': limit,
        },
      );

      if (res is Map<String, dynamic> && res['success'] == true) {
        final rawEvents = res['events'] as List? ?? [];
        final parsedEvents = <DistrictActivityEvent>[];

        for (final item in rawEvents) {
          if (item is Map<String, dynamic>) {
            parsedEvents.add(DistrictActivityEvent.fromJson(item));
          }
        }

        return _engine.filterByDistrict(parsedEvents, district);
      }

      return _buildOfflineFallback(district);
    } catch (e) {
      AppLogger.warn(
        'DistrictActivityRepository',
        'Failed to fetch district activity via RPC, using offline fallback',
        e,
      );
      return _buildOfflineFallback(district);
    }
  }

  List<DistrictActivityEvent> _buildOfflineFallback(String? district) {
    final now = DateTime.now();

    final allSeeds = [
      DistrictActivityEvent(
        id: 'seed-act-1',
        type: DistrictActivityType.dropCreated,
        userId: 'u-1',
        username: '@kamila_tashkent',
        userFullName: 'Kamila Karimova',
        district: 'Mirabad',
        placeName: 'Breadly Bakery & Café',
        placeId: 'pl-breadly',
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
      DistrictActivityEvent(
        id: 'seed-act-2',
        type: DistrictActivityType.routeCompleted,
        userId: 'u-2',
        username: '@jasur_brew',
        userFullName: 'Jasur Aliyev',
        district: 'Chilanzar',
        routeName: 'Chorsu Spice Trail',
        routeId: 'rt-chorsu',
        xpAwarded: 50,
        timestamp: now.subtract(const Duration(minutes: 18)),
      ),
      DistrictActivityEvent(
        id: 'seed-act-3',
        type: DistrictActivityType.crownOvertake,
        userId: 'u-3',
        username: '@nodir_walks',
        userFullName: 'Nodir Usmanov',
        district: 'Yakkasaray',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 10)),
      ),
      DistrictActivityEvent(
        id: 'seed-act-4',
        type: DistrictActivityType.badgeUnlocked,
        userId: 'u-4',
        username: '@aziza_art',
        userFullName: 'Aziza Tursunova',
        district: 'Yunusabad',
        badgeName: 'Historic Quarter Pioneer',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 40)),
      ),
      DistrictActivityEvent(
        id: 'seed-act-5',
        type: DistrictActivityType.placeVisited,
        userId: 'u-5',
        username: '@sardor_r',
        userFullName: 'Sardor Rakhimov',
        district: 'Mirabad',
        placeName: 'Afsona Restaurant',
        placeId: 'pl-afsona',
        timestamp: now.subtract(const Duration(hours: 4, minutes: 15)),
      ),
    ];

    return _engine.filterByDistrict(allSeeds, district);
  }
}

final districtActivityRepositoryProvider = Provider<DistrictActivityRepository>((ref) {
  final engine = ref.watch(districtActivityTickerEngineProvider);
  return DistrictActivityRepository(engine: engine);
});

final districtActivityEventsProvider =
    FutureProvider.family<List<DistrictActivityEvent>, String?>((ref, district) async {
  final repo = ref.watch(districtActivityRepositoryProvider);
  return repo.getDistrictActivityEvents(district: district);
});
