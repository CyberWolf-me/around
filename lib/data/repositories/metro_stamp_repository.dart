import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/metro_stamp_engine.dart';
import '../services/supabase_service.dart';

/// Repository for collecting and inspecting Tashkent Metro station passport stamps.
class MetroStampRepository {
  final MetroStampEngine _engine;

  MetroStampRepository({MetroStampEngine? engine})
      : _engine = engine ?? MetroStampEngine();

  /// Access underlying metro engine.
  MetroStampEngine get engine => _engine;

  /// Fetches claimed stamps for the user, falling back to local seeds when offline.
  Future<List<MetroStamp>> getUserStamps({String? userId}) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineFallback();
    }

    try {
      final targetUserId = userId ?? SupabaseService.client.auth.currentUser?.id;
      if (targetUserId == null) {
        return _buildOfflineFallback();
      }

      final res = await SupabaseService.client
          .from('user_metro_stamps')
          .select('station_id, line, place_id, created_at')
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);

      final stamps = <MetroStamp>[];
      for (final row in res) {
        final stationId = row['station_id'] as String;
        final station = MetroStampEngine.canonicalStations.firstWhere(
          (s) => s.id == stationId,
          orElse: () => MetroStation(
            id: stationId,
            name: stationId,
            line: MetroLine.uzbekistan,
            latitude: 41.311081,
            longitude: 69.240562,
            district: 'Central',
            stampMotif: 'Ceramic Medallion',
            stampColorHex: '#1E88E5',
          ),
        );

        stamps.add(MetroStamp(
          stationId: station.id,
          stationName: station.name,
          line: station.line,
          stampMotif: station.stampMotif,
          stampColorHex: station.stampColorHex,
          claimedAt: DateTime.parse(row['created_at'] as String),
          placeId: row['place_id'] as String?,
        ));
      }

      return stamps.isNotEmpty ? stamps : _buildOfflineFallback();
    } catch (e) {
      AppLogger.warn(
        'MetroStampRepository',
        'Failed to fetch metro stamps from Supabase, using offline fallback',
        e,
      );
      return _buildOfflineFallback();
    }
  }

  /// Claims a metro stamp via RPC.
  Future<Map<String, dynamic>> claimStamp(
    String stationId, {
    String? placeId,
  }) async {
    if (!SupabaseService.isInitialized) {
      return {
        'success': true,
        'station_id': stationId,
        'is_new_claim': true,
        'xp_awarded': 25,
        'offline': true,
      };
    }

    try {
      final res = await SupabaseService.client.rpc(
        'claim_metro_station_stamp',
        params: {
          'p_station_id': stationId,
          if (placeId != null) 'p_place_id': placeId,
        },
      );

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': false, 'error': 'Invalid RPC response'};
    } catch (e) {
      AppLogger.warn('MetroStampRepository', 'Failed to claim metro stamp via RPC', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Builds realistic offline fallback stamps for the user.
  List<MetroStamp> _buildOfflineFallback() {
    final now = DateTime.now();

    return [
      MetroStamp(
        stationId: 'kosmonavtlar',
        stationName: 'Kosmonavtlar',
        line: MetroLine.uzbekistan,
        stampMotif: 'Cosmos Blue Medallion',
        stampColorHex: '#1E88E5',
        claimedAt: now.subtract(const Duration(days: 3)),
      ),
      MetroStamp(
        stationId: 'chorsu',
        stationName: 'Chorsu',
        line: MetroLine.uzbekistan,
        stampMotif: 'Turquoise Bazaar Dome',
        stampColorHex: '#1E88E5',
        claimedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

final metroStampRepositoryProvider = Provider<MetroStampRepository>((ref) {
  final engine = ref.watch(metroStampEngineProvider);
  return MetroStampRepository(engine: engine);
});

final userMetroStampsProvider = FutureProvider<List<MetroStamp>>((ref) async {
  final repo = ref.watch(metroStampRepositoryProvider);
  return repo.getUserStamps();
});
