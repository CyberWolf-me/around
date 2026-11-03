import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/district_radio_engine.dart';
import '../services/supabase_service.dart';

/// Result from tuning into a district radio channel and logging session progress.
class RadioTuningSessionResult {
  final bool success;
  final String stationKey;
  final String callsign;
  final int durationSeconds;
  final int xpAwardedNow;
  final int totalXpEarned;
  final bool immersionAchieved;
  final String? errorMessage;

  const RadioTuningSessionResult({
    required this.success,
    required this.stationKey,
    required this.callsign,
    required this.durationSeconds,
    required this.xpAwardedNow,
    required this.totalXpEarned,
    required this.immersionAchieved,
    this.errorMessage,
  });

  factory RadioTuningSessionResult.fromMap(Map<String, dynamic> map) {
    return RadioTuningSessionResult(
      success: map['success'] as bool? ?? false,
      stationKey: map['station_key'] as String? ?? '',
      callsign: map['callsign'] as String? ?? '',
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      xpAwardedNow: (map['xp_awarded_now'] as num?)?.toInt() ?? 0,
      totalXpEarned: (map['total_xp_earned'] as num?)?.toInt() ?? 0,
      immersionAchieved: map['immersion_achieved'] as bool? ?? false,
      errorMessage: map['error'] as String?,
    );
  }
}

/// Repository for district radio streaming channels, frequency telemetry, and immersion sessions.
class DistrictRadioRepository {
  final DistrictRadioEngine _engine;

  DistrictRadioRepository({DistrictRadioEngine? engine})
      : _engine = engine ?? DistrictRadioEngine();

  DistrictRadioEngine get engine => _engine;

  /// Fetches all active district radio channels.
  Future<List<RadioStation>> getRadioChannels() async {
    if (!SupabaseService.isInitialized) {
      return _engine.getAllStations();
    }

    try {
      final res = await SupabaseService.client
          .from('district_radio_channels')
          .select('id, station_key, callsign, frequency_mhz, title, district, genre_description, accent_color_hex, stream_url, base_listeners, current_track, curator_name')
          .eq('is_active', true)
          .order('frequency_mhz', ascending: true);

      if (res.isEmpty) {
        return _engine.getAllStations();
      }

      final stations = <RadioStation>[];
      for (final row in res) {
        stations.add(RadioStation(
          id: row['station_key'] as String? ?? row['id'] as String,
          frequencyMhz: (row['frequency_mhz'] as num?)?.toDouble() ?? 88.0,
          callsign: row['callsign'] as String? ?? 'ARND',
          title: row['title'] as String? ?? 'District Radio',
          district: row['district'] as String? ?? 'Tashkent',
          genreDescription: row['genre_description'] as String? ?? 'Ambient',
          accentColorHex: row['accent_color_hex'] as String? ?? '#FF4800',
          streamUrl: row['stream_url'] as String? ?? '',
          baseListeners: (row['base_listeners'] as num?)?.toInt() ?? 100,
          currentTrack: row['current_track'] as String? ?? 'Atmosphere Stream',
          curatorName: row['curator_name'] as String? ?? 'Around Audio',
        ));
      }

      return stations.isNotEmpty ? stations : _engine.getAllStations();
    } catch (e) {
      AppLogger.warn(
        'DistrictRadioRepository',
        'Failed to query district_radio_channels from Supabase, falling back to defaults',
        e,
      );
      return _engine.getAllStations();
    }
  }

  /// Fetches the user's recorded listening durations per station.
  Future<Map<String, int>> getUserListeningSessions({String? userId}) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineSessionsFallback();
    }

    try {
      final targetUserId = userId ?? SupabaseService.client.auth.currentUser?.id;
      if (targetUserId == null) {
        return _buildOfflineSessionsFallback();
      }

      final res = await SupabaseService.client
          .from('radio_listening_sessions')
          .select('station_id, duration_seconds, district_radio_channels!inner(station_key)')
          .eq('user_id', targetUserId);

      final sessions = <String, int>{};
      for (final row in res) {
        final channelData = row['district_radio_channels'] as Map<String, dynamic>?;
        final stationKey = channelData?['station_key'] as String? ?? (row['station_id'] as String);
        final duration = (row['duration_seconds'] as num?)?.toInt() ?? 0;
        sessions[stationKey] = duration;
      }

      return sessions.isNotEmpty ? sessions : _buildOfflineSessionsFallback();
    } catch (e) {
      AppLogger.warn(
        'DistrictRadioRepository',
        'Failed to query radio_listening_sessions, returning offline fallback',
        e,
      );
      return _buildOfflineSessionsFallback();
    }
  }

  /// Logs a radio listening increment (e.g. 60 seconds) and awards XP if 600s threshold met.
  Future<RadioTuningSessionResult> tuneIntoRadio({
    required String stationKey,
    int durationSeconds = 60,
  }) async {
    if (!SupabaseService.isInitialized) {
      final station = _engine.getStationById(stationKey);
      final isThreshold = durationSeconds >= 600;
      return RadioTuningSessionResult(
        success: true,
        stationKey: stationKey,
        callsign: station?.callsign ?? 'ARND',
        durationSeconds: durationSeconds,
        xpAwardedNow: isThreshold ? 25 : 0,
        totalXpEarned: isThreshold ? 25 : 0,
        immersionAchieved: isThreshold,
      );
    }

    try {
      final response = await SupabaseService.client.rpc(
        'tune_into_district_radio',
        params: {
          'p_station_key': stationKey,
          'p_duration_seconds': durationSeconds,
        },
      );

      if (response == null || response is! Map<String, dynamic>) {
        return RadioTuningSessionResult(
          success: false,
          stationKey: stationKey,
          callsign: '',
          durationSeconds: 0,
          xpAwardedNow: 0,
          totalXpEarned: 0,
          immersionAchieved: false,
          errorMessage: 'Invalid RPC response format from tune_into_district_radio',
        );
      }

      return RadioTuningSessionResult.fromMap(response);
    } catch (e) {
      AppLogger.warn(
        'DistrictRadioRepository',
        'RPC tune_into_district_radio failed, falling back to local simulation',
        e,
      );
      final station = _engine.getStationById(stationKey);
      final isThreshold = durationSeconds >= 600;
      return RadioTuningSessionResult(
        success: true,
        stationKey: stationKey,
        callsign: station?.callsign ?? 'ARND',
        durationSeconds: durationSeconds,
        xpAwardedNow: isThreshold ? 25 : 0,
        totalXpEarned: isThreshold ? 25 : 0,
        immersionAchieved: isThreshold,
      );
    }
  }

  Map<String, int> _buildOfflineSessionsFallback() {
    return {
      'station-chorsu-fm': 420, // 7 mins
      'station-mirabad-beat': 650, // 10.8 mins (immersion completed)
      'station-yunusabad-rain': 180, // 3 mins
      'station-yakkasaray-breeze': 60, // 1 min
    };
  }
}

/// Riverpod provider for DistrictRadioRepository.
final districtRadioRepositoryProvider = Provider<DistrictRadioRepository>((ref) {
  final engine = ref.watch(districtRadioEngineProvider);
  return DistrictRadioRepository(engine: engine);
});

/// Riverpod future provider for district radio channels catalog.
final districtRadioStationsProvider =
    FutureProvider<List<RadioStation>>((ref) async {
  final repo = ref.watch(districtRadioRepositoryProvider);
  return repo.getRadioChannels();
});

/// Riverpod future provider for user listening durations.
final userRadioSessionsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(districtRadioRepositoryProvider);
  return repo.getUserListeningSessions();
});
