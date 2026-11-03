import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/metro_mosaic_engine.dart';
import '../services/supabase_service.dart';

/// Result from collecting a station mosaic exploration stamp.
class MetroStampResult {
  final bool success;
  final bool alreadyStamped;
  final String stationKey;
  final int pointsAwarded;
  final DateTime? createdAt;
  final String? errorMessage;

  const MetroStampResult({
    required this.success,
    required this.alreadyStamped,
    required this.stationKey,
    required this.pointsAwarded,
    this.createdAt,
    this.errorMessage,
  });

  factory MetroStampResult.fromMap(Map<String, dynamic> map) {
    return MetroStampResult(
      success: map['success'] as bool? ?? false,
      alreadyStamped: map['already_stamped'] as bool? ?? false,
      stationKey: map['station_key'] as String? ?? '',
      pointsAwarded: (map['points_awarded'] as num?)?.toInt() ?? 30,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      errorMessage: map['error'] as String?,
    );
  }
}

/// Repository for Tashkent Subway station architectural guides and digital stamps.
class MetroMosaicRepository {
  final MetroMosaicEngine _engine;

  MetroMosaicRepository({MetroMosaicEngine? engine})
      : _engine = engine ?? MetroMosaicEngine();

  MetroMosaicEngine get engine => _engine;

  /// Fetches all active metro stations, optionally filtered by line.
  Future<List<MetroStationModel>> getStations({MetroLine? line}) async {
    if (!SupabaseService.isInitialized) {
      final list = line != null ? _engine.getStationsByLine(line) : _engine.stations;
      return list;
    }

    try {
      var query = SupabaseService.client
          .from('metro_stations')
          .select('id, station_key, name_uz, name_ru, name_en, line_id, opening_year, architect, mosaic_artist, architectural_style, mosaic_description, marble_pillars, lighting_style, audio_guide_track_url, audio_guide_snippet_uz, audio_guide_snippet_ru, audio_guide_snippet_en, latitude, longitude, stamp_points')
          .eq('is_active', true);

      if (line != null) {
        query = query.eq('line_id', line.id);
      }

      final res = await query.order('opening_year', ascending: true);

      if (res.isEmpty) {
        return line != null ? _engine.getStationsByLine(line) : _engine.stations;
      }

      final stations = <MetroStationModel>[];
      for (final row in res) {
        final station = MetroStationModel(
          id: row['station_key'] as String,
          nameUz: row['name_uz'] as String? ?? '',
          nameRu: row['name_ru'] as String? ?? '',
          nameEn: row['name_en'] as String? ?? '',
          line: MetroLine.fromId(row['line_id'] as String? ?? 'uzbekistan'),
          openingYear: (row['opening_year'] as num?)?.toInt() ?? 1984,
          architect: row['architect'] as String? ?? '',
          mosaicArtist: row['mosaic_artist'] as String? ?? '',
          architecturalStyle: row['architectural_style'] as String? ?? '',
          mosaicDescription: row['mosaic_description'] as String? ?? '',
          marblePillars: row['marble_pillars'] as String? ?? '',
          lightingStyle: row['lighting_style'] as String? ?? '',
          audioGuideTrackUrl: row['audio_guide_track_url'] as String? ?? '',
          audioGuideSnippetUz: row['audio_guide_snippet_uz'] as String? ?? '',
          audioGuideSnippetRu: row['audio_guide_snippet_ru'] as String? ?? '',
          audioGuideSnippetEn: row['audio_guide_snippet_en'] as String? ?? '',
          latitude: (row['latitude'] as num?)?.toDouble() ?? 41.311081,
          longitude: (row['longitude'] as num?)?.toDouble() ?? 69.240562,
          stampPoints: (row['stamp_points'] as num?)?.toInt() ?? 30,
        );
        stations.add(station);
      }

      return stations;
    } catch (e) {
      AppLogger.warn('MetroMosaic', 'Failed to load metro stations from Supabase: $e', e);
      return line != null ? _engine.getStationsByLine(line) : _engine.stations;
    }
  }

  /// Fetches stamps collected by the current user.
  Future<List<MetroVisitStamp>> getUserStamps() async {
    if (!SupabaseService.isInitialized) {
      return [];
    }

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final res = await SupabaseService.client
          .from('metro_mosaic_stamps')
          .select('id, user_id, notes, photo_proof_url, points_awarded, created_at, metro_stations(station_key)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final stamps = <MetroVisitStamp>[];
      for (final row in res) {
        final stationRow = row['metro_stations'] as Map<String, dynamic>?;
        final stationKey = stationRow != null ? (stationRow['station_key'] as String? ?? '') : '';

        stamps.add(
          MetroVisitStamp(
            stationId: stationKey,
            visitedAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
            photoProofUrl: row['photo_proof_url'] as String?,
            notes: row['notes'] as String?,
            pointsEarned: (row['points_awarded'] as num?)?.toInt() ?? 30,
          ),
        );
      }
      return stamps;
    } catch (e) {
      AppLogger.warn('MetroMosaic', 'Failed to fetch user metro stamps: $e', e);
      return [];
    }
  }

  /// Collects a digital exploration stamp (+30 XP) via Security Definer RPC.
  Future<MetroStampResult> collectStationStamp({
    required String stationKey,
    String? notes,
    String? photoProofUrl,
  }) async {
    if (!SupabaseService.isInitialized) {
      final station = _engine.findStationById(stationKey);
      if (station == null) {
        return MetroStampResult(
          success: false,
          alreadyStamped: false,
          stationKey: stationKey,
          pointsAwarded: 0,
          errorMessage: 'Station not found.',
        );
      }

      return MetroStampResult(
        success: true,
        alreadyStamped: false,
        stationKey: stationKey,
        pointsAwarded: station.stampPoints,
        createdAt: DateTime.now(),
      );
    }

    try {
      final response = await SupabaseService.client.rpc(
        'collect_metro_mosaic_stamp',
        params: {
          'p_station_key': stationKey,
          'p_notes': notes,
          'p_photo_proof_url': photoProofUrl,
        },
      );

      if (response == null) {
        return MetroStampResult(
          success: false,
          alreadyStamped: false,
          stationKey: stationKey,
          pointsAwarded: 0,
          errorMessage: 'RPC response was null.',
        );
      }

      final map = Map<String, dynamic>.from(response as Map);
      return MetroStampResult.fromMap(map);
    } catch (e) {
      AppLogger.error('MetroMosaic', 'Failed to execute collect_metro_mosaic_stamp RPC: $e', e);
      return MetroStampResult(
        success: false,
        alreadyStamped: false,
        stationKey: stationKey,
        pointsAwarded: 0,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Riverpod Providers for Metro Architecture & Mosaic Vaults.
final metroMosaicRepositoryProvider = Provider<MetroMosaicRepository>((ref) {
  final engine = ref.watch(metroMosaicEngineProvider);
  return MetroMosaicRepository(engine: engine);
});

final metroStationsProvider = FutureProvider<List<MetroStationModel>>((ref) {
  final repository = ref.watch(metroMosaicRepositoryProvider);
  return repository.getStations();
});

final userMetroStampsProvider = FutureProvider<List<MetroVisitStamp>>((ref) {
  final repository = ref.watch(metroMosaicRepositoryProvider);
  return repository.getUserStamps();
});
