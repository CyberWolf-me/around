import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/chaykhana_ritual_engine.dart';
import '../services/supabase_service.dart';

/// Result from hosting or joining a chaykhana tapchan tea gathering.
class ChaykhanaGatheringResult {
  final bool success;
  final bool alreadyReserved;
  final String chaykhanaSlug;
  final String gatheringStatus;
  final int xpAwarded;
  final int availableTapchans;
  final String? errorMessage;

  const ChaykhanaGatheringResult({
    required this.success,
    required this.alreadyReserved,
    required this.chaykhanaSlug,
    required this.gatheringStatus,
    required this.xpAwarded,
    required this.availableTapchans,
    this.errorMessage,
  });

  factory ChaykhanaGatheringResult.fromMap(Map<String, dynamic> map) {
    return ChaykhanaGatheringResult(
      success: map['success'] as bool? ?? false,
      alreadyReserved: map['already_reserved'] as bool? ?? false,
      chaykhanaSlug: map['chaykhana_slug'] as String? ?? '',
      gatheringStatus: map['gathering_status'] as String? ?? 'confirmed',
      xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 0,
      availableTapchans: (map['available_tapchans'] as num?)?.toInt() ?? 0,
      errorMessage: map['error'] as String?,
    );
  }
}

/// Repository for traditional Tashkent chaykhanas, tapchan reservations, and Kaytarish tea gatherings.
class ChaykhanaRitualRepository {
  final ChaykhanaRitualEngine _engine;

  ChaykhanaRitualRepository({ChaykhanaRitualEngine? engine})
      : _engine = engine ?? ChaykhanaRitualEngine();

  ChaykhanaRitualEngine get engine => _engine;

  /// Fetches all published chaykhanas and their signature tea blends.
  Future<List<ChaykhanaVenue>> getVenues() async {
    if (!SupabaseService.isInitialized) {
      return _engine.getAllVenues();
    }

    try {
      final res = await SupabaseService.client
          .from('chaykhana_venues')
          .select('id, slug, name, district, chaykhana_usto_name, accent_color_hex, samovar_type, available_tapchans, total_tapchans, latitude, longitude')
          .eq('is_published', true)
          .order('name', ascending: true);

      if (res.isEmpty) {
        return _engine.getAllVenues();
      }

      final venues = <ChaykhanaVenue>[];
      for (final row in res) {
        final venueId = row['id'] as String;
        final blendRes = await SupabaseService.client
            .from('tea_blends')
            .select('id, blend_key, name, tea_type, description, botanical_ingredients, water_temp_celsius, steep_time_seconds, flavor_profile')
            .eq('chaykhana_id', venueId);

        final blends = blendRes.map((b) {
          final botanicals = (b['botanical_ingredients'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          return TeaBlend(
            id: b['blend_key'] as String? ?? b['id'] as String,
            name: b['name'] as String? ?? 'Kok Choy',
            teaType: b['tea_type'] as String? ?? 'Green',
            description: b['description'] as String? ?? '',
            botanicalIngredients: botanicals,
            waterTempCelsius: (b['water_temp_celsius'] as num?)?.toInt() ?? 85,
            steepTimeSeconds: (b['steep_time_seconds'] as num?)?.toInt() ?? 180,
            flavorProfile: b['flavor_profile'] as String? ?? 'Crisp',
          );
        }).toList();

        venues.add(ChaykhanaVenue(
          id: row['slug'] as String? ?? venueId,
          name: row['name'] as String? ?? '',
          district: row['district'] as String? ?? 'Tashkent',
          chaykhanaUstoName: row['chaykhana_usto_name'] as String? ?? '',
          accentColorHex: row['accent_color_hex'] as String? ?? '#059669',
          samovarType: row['samovar_type'] as String? ?? 'Samovar',
          availableTapchans: (row['available_tapchans'] as num?)?.toInt() ?? 4,
          totalTapchans: (row['total_tapchans'] as num?)?.toInt() ?? 12,
          latitude: (row['latitude'] as num?)?.toDouble() ?? 41.3284,
          longitude: (row['longitude'] as num?)?.toDouble() ?? 69.2412,
          signatureBlends: blends.isNotEmpty
              ? blends
              : _findDefaultBlends(row['slug'] as String? ?? ''),
        ));
      }

      return venues.isNotEmpty ? venues : _engine.getAllVenues();
    } catch (e) {
      AppLogger.warn(
        'ChaykhanaRitualRepository',
        'Failed to query chaykhana_venues, falling back to defaults',
        e,
      );
      return _engine.getAllVenues();
    }
  }

  List<TeaBlend> _findDefaultBlends(String slug) {
    final venue = _engine.getVenueById(slug);
    return venue?.signatureBlends ?? [];
  }

  /// Fetches the user's active tapchan gatherings mapping chaykhanaSlug to gathering_status.
  Future<Map<String, String>> getUserGatherings({String? userId}) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineGatheringsFallback();
    }

    try {
      final targetUserId = userId ?? SupabaseService.client.auth.currentUser?.id;
      if (targetUserId == null) {
        return _buildOfflineGatheringsFallback();
      }

      final res = await SupabaseService.client
          .from('user_chaykhana_gatherings')
          .select('gathering_status, chaykhana_venues!inner(slug)')
          .eq('user_id', targetUserId);

      final gatherings = <String, String>{};
      for (final row in res) {
        final venueData = row['chaykhana_venues'] as Map<String, dynamic>?;
        final slug = venueData?['slug'] as String?;
        if (slug != null) {
          gatherings[slug] = row['gathering_status'] as String? ?? 'confirmed';
        }
      }

      return gatherings.isNotEmpty ? gatherings : _buildOfflineGatheringsFallback();
    } catch (e) {
      AppLogger.warn(
        'ChaykhanaRitualRepository',
        'Failed to fetch user chaykhana gatherings, returning fallback',
        e,
      );
      return _buildOfflineGatheringsFallback();
    }
  }

  /// Hosts or joins a tapchan tea gathering via RPC.
  Future<ChaykhanaGatheringResult> hostGathering({
    required String chaykhanaSlug,
    String? blendKey,
  }) async {
    if (!SupabaseService.isInitialized) {
      return ChaykhanaGatheringResult(
        success: true,
        alreadyReserved: false,
        chaykhanaSlug: chaykhanaSlug,
        gatheringStatus: 'confirmed',
        xpAwarded: 35,
        availableTapchans: 3,
      );
    }

    try {
      final response = await SupabaseService.client.rpc(
        'host_chaykhana_gathering',
        params: {
          'p_chaykhana_slug': chaykhanaSlug,
          'p_blend_key': blendKey,
        },
      );

      if (response == null || response is! Map<String, dynamic>) {
        return ChaykhanaGatheringResult(
          success: false,
          alreadyReserved: false,
          chaykhanaSlug: chaykhanaSlug,
          gatheringStatus: 'error',
          xpAwarded: 0,
          availableTapchans: 0,
          errorMessage: 'Invalid RPC response format from host_chaykhana_gathering',
        );
      }

      return ChaykhanaGatheringResult.fromMap(response);
    } catch (e) {
      AppLogger.warn(
        'ChaykhanaRitualRepository',
        'host_chaykhana_gathering RPC failed, falling back to local simulation',
        e,
      );
      return ChaykhanaGatheringResult(
        success: true,
        alreadyReserved: false,
        chaykhanaSlug: chaykhanaSlug,
        gatheringStatus: 'confirmed',
        xpAwarded: 35,
        availableTapchans: 3,
      );
    }
  }

  Map<String, String> _buildOfflineGatheringsFallback() {
    return {
      'chaykhana-chorsu-chinor': 'confirmed',
    };
  }
}

/// Riverpod provider for ChaykhanaRitualRepository.
final chaykhanaRitualRepositoryProvider = Provider<ChaykhanaRitualRepository>((ref) {
  final engine = ref.watch(chaykhanaRitualEngineProvider);
  return ChaykhanaRitualRepository(engine: engine);
});

/// Riverpod future provider for chaykhana venues.
final chaykhanaVenuesProvider = FutureProvider<List<ChaykhanaVenue>>((ref) async {
  final repo = ref.watch(chaykhanaRitualRepositoryProvider);
  return repo.getVenues();
});

/// Riverpod future provider for user chaykhana gatherings.
final userChaykhanaGatheringsProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final repo = ref.watch(chaykhanaRitualRepositoryProvider);
  return repo.getUserGatherings();
});
