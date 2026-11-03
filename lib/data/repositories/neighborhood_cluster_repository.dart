import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/neighborhood_cluster_engine.dart';
import '../services/supabase_service.dart';

/// Repository for retrieving privacy-safe neighborhood activity clusters across Tashkent.
class NeighborhoodClusterRepository {
  final NeighborhoodClusterEngine _engine;

  NeighborhoodClusterRepository({NeighborhoodClusterEngine? engine})
      : _engine = engine ?? NeighborhoodClusterEngine();

  /// Returns the underlying spatial cluster engine.
  NeighborhoodClusterEngine get engine => _engine;

  /// Aggregates raw spatial drop points into privacy-safe neighborhood clusters.
  List<NeighborhoodCluster> clusterDrops(List<SpatialDropPoint> drops) {
    return _engine.clusterDrops(drops);
  }

  /// Fetches aggregated spatial clusters, falling back to rich local seeds when offline.
  Future<List<NeighborhoodCluster>> getNeighborhoodClusters({
    String? district,
    double? gridStep,
  }) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineFallback(district);
    }

    try {
      final res = await SupabaseService.client.rpc(
        'get_neighborhood_drop_clusters',
        params: {
          if (district != null) 'p_district': district,
          if (gridStep != null) 'p_grid_step': gridStep,
        },
      );

      if (res is Map<String, dynamic> && res['success'] == true) {
        final rawClusters = res['clusters'] as List? ?? [];
        final clusters = <NeighborhoodCluster>[];

        for (final item in rawClusters) {
          if (item is Map<String, dynamic>) {
            clusters.add(NeighborhoodCluster.fromJson(item));
          }
        }

        if (clusters.isNotEmpty) {
          return clusters;
        }
      }

      return _buildOfflineFallback(district);
    } catch (e) {
      AppLogger.warn(
        'NeighborhoodClusterRepository',
        'Failed to fetch neighborhood clusters via RPC, using offline fallback',
        e,
      );
      return _buildOfflineFallback(district);
    }
  }

  /// Builds realistic offline seeds across central Tashkent districts.
  List<NeighborhoodCluster> _buildOfflineFallback(String? district) {
    const allSeeds = [
      NeighborhoodCluster(
        id: 'cluster_mirabad_glinka',
        centroidLat: 41.2985,
        centroidLng: 69.2715,
        district: 'Mirabad',
        intensity: ClusterIntensity.peak,
        dropsCount: 14,
        venueNames: [
          'Breadly Bakery & Café',
          'Socials Café',
          'Glinka Roastery',
        ],
        primaryVenueName: 'Breadly Bakery & Café',
      ),
      NeighborhoodCluster(
        id: 'cluster_shaykhontohur_chorsu',
        centroidLat: 41.3275,
        centroidLng: 69.2361,
        district: 'Shaykhontohur',
        intensity: ClusterIntensity.buzzing,
        dropsCount: 9,
        venueNames: [
          'Chorsu Dome Bazaar',
          'Kukeldash Courtyard',
          'Old City Chaykhana',
        ],
        primaryVenueName: 'Chorsu Dome Bazaar',
      ),
      NeighborhoodCluster(
        id: 'cluster_yakkasaray_pedestrian',
        centroidLat: 41.2912,
        centroidLng: 69.2554,
        district: 'Yakkasaray',
        intensity: ClusterIntensity.lively,
        dropsCount: 5,
        venueNames: [
          'Shota Rustaveli Square',
          'Book Café Art Space',
        ],
        primaryVenueName: 'Shota Rustaveli Square',
      ),
      NeighborhoodCluster(
        id: 'cluster_yunusabad_tv_tower',
        centroidLat: 41.3508,
        centroidLng: 69.2845,
        district: 'Yunusabad',
        intensity: ClusterIntensity.serene,
        dropsCount: 2,
        venueNames: [
          'Tashkent TV Tower Promenade',
          'Besh Qozon Pilaf Center',
        ],
        primaryVenueName: 'Tashkent TV Tower Promenade',
      ),
      NeighborhoodCluster(
        id: 'cluster_chilanzar_novza',
        centroidLat: 41.2854,
        centroidLng: 69.2152,
        district: 'Chilanzar',
        intensity: ClusterIntensity.lively,
        dropsCount: 4,
        venueNames: [
          'Novza Mosque Plaza',
          'Bunyodkor Avenue Bakery',
        ],
        primaryVenueName: 'Novza Mosque Plaza',
      ),
    ];

    if (district == null || district.trim().isEmpty || district.toLowerCase() == 'all') {
      return allSeeds;
    }

    final query = district.trim().toLowerCase();
    return allSeeds.where((c) => c.district.toLowerCase() == query).toList();
  }
}

final neighborhoodClusterRepositoryProvider = Provider<NeighborhoodClusterRepository>((ref) {
  final engine = ref.watch(neighborhoodClusterEngineProvider);
  return NeighborhoodClusterRepository(engine: engine);
});

final neighborhoodClustersProvider =
    FutureProvider.family<List<NeighborhoodCluster>, String?>((ref, district) async {
  final repo = ref.watch(neighborhoodClusterRepositoryProvider);
  return repo.getNeighborhoodClusters(district: district);
});
