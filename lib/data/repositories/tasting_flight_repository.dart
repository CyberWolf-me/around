import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/tasting_flight_engine.dart';
import '../services/supabase_service.dart';

/// Result from logging a tasting flight cupping experience.
class TastingCuppingResult {
  final bool success;
  final String flightSlug;
  final String stopKey;
  final int completedCount;
  final int requiredStops;
  final double averageScore;
  final bool isCompleted;
  final bool certificateAwardedNow;
  final String curatorTitle;
  final int xpAwarded;
  final String? errorMessage;

  const TastingCuppingResult({
    required this.success,
    required this.flightSlug,
    required this.stopKey,
    required this.completedCount,
    required this.requiredStops,
    required this.averageScore,
    required this.isCompleted,
    required this.certificateAwardedNow,
    required this.curatorTitle,
    required this.xpAwarded,
    this.errorMessage,
  });

  factory TastingCuppingResult.fromMap(Map<String, dynamic> map) {
    return TastingCuppingResult(
      success: map['success'] as bool? ?? false,
      flightSlug: map['flight_slug'] as String? ?? '',
      stopKey: map['stop_key'] as String? ?? '',
      completedCount: (map['completed_count'] as num?)?.toInt() ?? 0,
      requiredStops: (map['required_stops'] as num?)?.toInt() ?? 0,
      averageScore: (map['average_score'] as num?)?.toDouble() ?? 0.0,
      isCompleted: map['is_completed'] as bool? ?? false,
      certificateAwardedNow: map['certificate_awarded_now'] as bool? ?? false,
      curatorTitle: map['curator_title'] as String? ?? '',
      xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 0,
      errorMessage: map['error'] as String?,
    );
  }
}

/// Repository for artisan tasting flights, cupping notes, and certificates.
class TastingFlightRepository {
  final TastingFlightEngine _engine;

  TastingFlightRepository({TastingFlightEngine? engine})
      : _engine = engine ?? TastingFlightEngine();

  TastingFlightEngine get engine => _engine;

  /// Fetches all available tasting flights.
  Future<List<TastingFlight>> getFlights() async {
    if (!SupabaseService.isInitialized) {
      return _engine.getAllFlights();
    }

    try {
      final res = await SupabaseService.client
          .from('tasting_flights')
          .select('id, slug, title, curator_title, description, category, flight_icon, accent_color_hex, required_stops_count, xp_reward')
          .eq('is_published', true)
          .order('created_at', ascending: true);

      if (res.isEmpty) {
        return _engine.getAllFlights();
      }

      final flights = <TastingFlight>[];
      for (final row in res) {
        final flightId = row['id'] as String;
        final stopsRes = await SupabaseService.client
            .from('tasting_flight_stops')
            .select('id, place_id, venue_name, district, item_title, flavor_notes, origin_story, suggested_serving_temp, latitude, longitude')
            .eq('flight_id', flightId)
            .order('created_at', ascending: true);

        final stops = stopsRes
            .map((s) => TastingStop.fromJson(s))
            .toList();

        flights.add(TastingFlight(
          id: flightId,
          slug: row['slug'] as String? ?? '',
          title: row['title'] as String? ?? '',
          curatorTitle: row['curator_title'] as String? ?? '',
          description: row['description'] as String? ?? '',
          category: row['category'] as String? ?? 'Coffee',
          flightIcon: row['flight_icon'] as String? ?? 'cup.and.saucer',
          accentColorHex: row['accent_color_hex'] as String? ?? '#A259FF',
          requiredStopsCount: (row['required_stops_count'] as num?)?.toInt() ?? 3,
          xpReward: (row['xp_reward'] as num?)?.toInt() ?? 50,
          stops: stops.isNotEmpty ? stops : _findDefaultStops(row['slug'] as String? ?? ''),
        ));
      }

      return flights.isNotEmpty ? flights : _engine.getAllFlights();
    } catch (e) {
      AppLogger.warn(
        'TastingFlightRepository',
        'Failed to query tasting_flights from Supabase, using defaults',
        e,
      );
      return _engine.getAllFlights();
    }
  }

  List<TastingStop> _findDefaultStops(String slug) {
    final defaultFlight = _engine.getFlightById(slug);
    return defaultFlight?.stops ?? [];
  }

  /// Fetches the user's logged cupping ratings and flavor notes.
  Future<Map<String, TastingLog>> getUserTastingLogs({String? userId}) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineLogsFallback();
    }

    try {
      final targetUserId = userId ?? SupabaseService.client.auth.currentUser?.id;
      if (targetUserId == null) {
        return _buildOfflineLogsFallback();
      }

      final res = await SupabaseService.client
          .from('user_tasting_logs')
          .select('stop_key, place_id, rating, flavor_notes, tasting_notes, logged_at')
          .eq('user_id', targetUserId);

      final logs = <String, TastingLog>{};
      for (final row in res) {
        final stopKey = row['stop_key'] as String;
        final notes = (row['flavor_notes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        final log = TastingLog(
          stopId: stopKey,
          rating: (row['rating'] as num?)?.toDouble() ?? 8.0,
          selectedFlavorNotes: notes,
          tastingNotes: row['tasting_notes'] as String?,
          loggedAt: row['logged_at'] != null
              ? DateTime.tryParse(row['logged_at'] as String) ?? DateTime.now()
              : DateTime.now(),
        );

        logs[stopKey] = log;
        logs['stop-$stopKey'] = log;

        final placeId = row['place_id'] as String?;
        if (placeId != null && placeId.isNotEmpty) {
          logs[placeId] = log;
        }
      }

      return logs.isNotEmpty ? logs : _buildOfflineLogsFallback();
    } catch (e) {
      AppLogger.warn(
        'TastingFlightRepository',
        'Failed to fetch user tasting logs from Supabase, using fallback',
        e,
      );
      return _buildOfflineLogsFallback();
    }
  }

  /// Records a cupping score for a flight stop via RPC.
  Future<TastingCuppingResult> recordCupping({
    required String flightSlug,
    required String stopKey,
    required double rating,
    List<String> flavorNotes = const [],
    String? tastingNotes,
    String? placeId,
  }) async {
    if (!SupabaseService.isInitialized) {
      return TastingCuppingResult(
        success: true,
        flightSlug: flightSlug,
        stopKey: stopKey,
        completedCount: 1,
        requiredStops: 3,
        averageScore: rating,
        isCompleted: false,
        certificateAwardedNow: false,
        curatorTitle: 'Specialty Coffee Cupping Certificate',
        xpAwarded: 0,
      );
    }

    try {
      final res = await SupabaseService.client.rpc(
        'record_tasting_flight_cupping',
        params: {
          'p_flight_slug': flightSlug,
          'p_stop_key': stopKey,
          'p_rating': rating,
          'p_flavor_notes': flavorNotes,
          if (tastingNotes != null) 'p_tasting_notes': tastingNotes,
          if (placeId != null) 'p_place_id': placeId,
        },
      );

      final map = Map<String, dynamic>.from(res as Map);
      return TastingCuppingResult.fromMap(map);
    } catch (e) {
      AppLogger.error(
        'TastingFlightRepository',
        'RPC record_tasting_flight_cupping failed',
        e,
      );
      return TastingCuppingResult(
        success: false,
        flightSlug: flightSlug,
        stopKey: stopKey,
        completedCount: 0,
        requiredStops: 0,
        averageScore: 0.0,
        isCompleted: false,
        certificateAwardedNow: false,
        curatorTitle: '',
        xpAwarded: 0,
        errorMessage: e.toString(),
      );
    }
  }

  Map<String, TastingLog> _buildOfflineLogsFallback() {
    return {
      'breadly-cupping': TastingLog(
        stopId: 'breadly-cupping',
        rating: 9.3,
        selectedFlavorNotes: const ['Bergamot', 'Dried Peach'],
        tastingNotes: 'Crisp floral aromatics and clean peach finish.',
        loggedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      'stop-breadly-cupping': TastingLog(
        stopId: 'stop-breadly-cupping',
        rating: 9.3,
        selectedFlavorNotes: const ['Bergamot', 'Dried Peach'],
        tastingNotes: 'Crisp floral aromatics and clean peach finish.',
        loggedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    };
  }
}

/// Riverpod provider for TastingFlightRepository.
final tastingFlightRepositoryProvider = Provider<TastingFlightRepository>((ref) {
  final engine = ref.watch(tastingFlightEngineProvider);
  return TastingFlightRepository(engine: engine);
});

/// Riverpod provider for tasting flights catalog.
final tastingFlightsProvider = FutureProvider<List<TastingFlight>>((ref) async {
  final repo = ref.watch(tastingFlightRepositoryProvider);
  return repo.getFlights();
});

/// Riverpod provider for user's cupping logs.
final userTastingLogsProvider = FutureProvider<Map<String, TastingLog>>((ref) async {
  final repo = ref.watch(tastingFlightRepositoryProvider);
  return repo.getUserTastingLogs();
});
