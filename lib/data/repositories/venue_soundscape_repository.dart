import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/venue_soundscape_engine.dart';
import '../services/supabase_service.dart';

/// Repository for resolving ambient acoustic soundscape presets for Tashkent venues.
class VenueSoundscapeRepository {
  final VenueSoundscapeEngine _engine;

  VenueSoundscapeRepository({VenueSoundscapeEngine? engine})
      : _engine = engine ?? VenueSoundscapeEngine();

  /// Resolves the soundscape configuration for a given place ID, with offline category matching.
  Future<SoundscapePresetConfig> getVenueSoundscape({
    required String placeId,
    String? placeCategory,
    int? hourOfDay,
  }) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineFallback(placeCategory, hourOfDay);
    }

    try {
      final res = await SupabaseService.client.rpc(
        'get_venue_soundscape_preset',
        params: {'p_place_id': placeId},
      );

      if (res is Map && res['success'] == true) {
        final rawPreset = res['soundscape_preset'] as String? ?? 'espresso_murmur';
        final preset = _parsePreset(rawPreset, placeCategory, hourOfDay);
        return _engine.getConfig(preset);
      }

      return _buildOfflineFallback(placeCategory, hourOfDay);
    } catch (e) {
      AppLogger.warn(
        'VenueSoundscapeRepository',
        'Failed to query venue soundscape preset via RPC, using offline fallback',
        e,
      );
      return _buildOfflineFallback(placeCategory, hourOfDay);
    }
  }

  VenueSoundscapePreset _parsePreset(String rawPreset, String? fallbackCategory, int? hourOfDay) {
    switch (rawPreset.toLowerCase().trim()) {
      case 'oriental_bazaar':
      case 'orientalbazaar':
        return VenueSoundscapePreset.orientalBazaar;
      case 'courtyard_fountain':
      case 'courtyardfountain':
        return VenueSoundscapePreset.courtyardFountain;
      case 'jazz_lounge':
      case 'jazzlounge':
        return VenueSoundscapePreset.jazzLounge;
      case 'quiet_library':
      case 'quietlibrary':
        return VenueSoundscapePreset.quietLibrary;
      case 'espresso_murmur':
      case 'espressomurmur':
        return VenueSoundscapePreset.espressoMurmur;
      default:
        return _engine.recommendPreset(venueCategory: fallbackCategory ?? 'Cafe', hourOfDay: hourOfDay);
    }
  }

  SoundscapePresetConfig _buildOfflineFallback(String? placeCategory, int? hourOfDay) {
    final preset = _engine.recommendPreset(venueCategory: placeCategory ?? 'Cafe', hourOfDay: hourOfDay);
    return _engine.getConfig(preset);
  }
}

final venueSoundscapeRepositoryProvider = Provider<VenueSoundscapeRepository>((ref) {
  final engine = ref.watch(venueSoundscapeEngineProvider);
  return VenueSoundscapeRepository(engine: engine);
});

final venueSoundscapePresetProvider =
    FutureProvider.family<SoundscapePresetConfig, String>((ref, placeId) async {
  final repo = ref.watch(venueSoundscapeRepositoryProvider);
  return repo.getVenueSoundscape(placeId: placeId);
});
