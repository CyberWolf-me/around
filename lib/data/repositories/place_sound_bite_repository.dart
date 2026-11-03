import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/place_sound_bite_engine.dart';
import '../services/supabase_service.dart';

/// Repository for managing community voice notes and courtyard whispers for places.
class PlaceSoundBiteRepository {
  final PlaceSoundBiteEngine _engine;

  PlaceSoundBiteRepository({PlaceSoundBiteEngine? engine})
      : _engine = engine ?? PlaceSoundBiteEngine();

  /// Access underlying sound bite engine.
  PlaceSoundBiteEngine get engine => _engine;

  /// Fetches community sound bites for a place, gracefully falling back to local seeds if offline.
  Future<List<PlaceSoundBite>> getPlaceSoundBites({
    required String placeId,
    int limit = 10,
  }) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineFallback(placeId);
    }

    try {
      final res = await SupabaseService.client.rpc(
        'get_place_sound_bites',
        params: {
          'p_place_id': placeId,
          'p_limit': limit,
        },
      );

      if (res is Map<String, dynamic> && res['success'] == true) {
        final rawBites = res['sound_bites'] as List? ?? [];
        final bites = <PlaceSoundBite>[];

        for (final item in rawBites) {
          if (item is Map<String, dynamic>) {
            bites.add(PlaceSoundBite.fromJson(item));
          }
        }

        if (bites.isNotEmpty) {
          return bites;
        }
      }

      return _buildOfflineFallback(placeId);
    } catch (e) {
      AppLogger.warn(
        'PlaceSoundBiteRepository',
        'Failed to fetch place sound bites via RPC, using offline fallback',
        e,
      );
      return _buildOfflineFallback(placeId);
    }
  }

  /// Builds realistic offline seeds across iconic Tashkent venues.
  List<PlaceSoundBite> _buildOfflineFallback(String placeId) {
    final now = DateTime.now();

    final allSeeds = [
      PlaceSoundBite(
        id: 'sb-seed-breadly-1',
        placeId: 'pl-breadly',
        placeName: 'Breadly Bakery & Café',
        district: 'Mirabad',
        authorId: 'u-kamila',
        authorName: 'Kamila Karimova',
        audioUrl: 'https://cdn.around.uz/audio/breadly-croissant.m4a',
        durationSeconds: 22,
        waveformAmplitudes: const [0.3, 0.5, 0.8, 0.9, 0.7, 0.4, 0.6, 0.8, 0.5, 0.3],
        transcriptionSnippet: 'The almond croissants straight from the oven at 8:30 AM are unmatched.',
        categoryTag: 'barista_tip',
        likesCount: 24,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      PlaceSoundBite(
        id: 'sb-seed-breadly-2',
        placeId: 'pl-breadly',
        placeName: 'Breadly Bakery & Café',
        district: 'Mirabad',
        authorId: 'u-jasur',
        authorName: 'Jasur Aliyev',
        audioUrl: 'https://cdn.around.uz/audio/breadly-vibes.m4a',
        durationSeconds: 16,
        waveformAmplitudes: const [0.2, 0.4, 0.6, 0.7, 0.5, 0.3, 0.4, 0.2],
        transcriptionSnippet: 'Gentle morning jazz on the back patio with a double cortado.',
        categoryTag: 'ambient',
        likesCount: 15,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      PlaceSoundBite(
        id: 'sb-seed-chorsu-1',
        placeId: 'pl-chorsu',
        placeName: 'Chorsu Dome Bazaar',
        district: 'Shaykhontohur',
        authorId: 'u-nodir',
        authorName: 'Nodir Usmanov',
        audioUrl: 'https://cdn.around.uz/audio/chorsu-spice.m4a',
        durationSeconds: 34,
        waveformAmplitudes: const [0.4, 0.7, 0.9, 0.8, 0.9, 0.6, 0.8, 0.7, 0.5, 0.4],
        transcriptionSnippet: 'Listen to the saffron sellers and the echo under the grand turquoise dome.',
        categoryTag: 'whisper',
        likesCount: 38,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      PlaceSoundBite(
        id: 'sb-seed-kukeldash-1',
        placeId: 'pl-kukeldash',
        placeName: 'Kukeldash Courtyard',
        district: 'Shaykhontohur',
        authorId: 'u-aziza',
        authorName: 'Aziza Tursunova',
        audioUrl: 'https://cdn.around.uz/audio/kukeldash-breeze.m4a',
        durationSeconds: 28,
        waveformAmplitudes: const [0.2, 0.3, 0.5, 0.6, 0.4, 0.5, 0.3, 0.2],
        transcriptionSnippet: 'A 500-year-old carved wooden pillar garden bathed in afternoon stillness.',
        categoryTag: 'history',
        likesCount: 29,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    if (placeId.trim().isEmpty || placeId.toLowerCase() == 'all') {
      return allSeeds;
    }

    final query = placeId.trim().toLowerCase();
    final matching = allSeeds.where((b) => b.placeId.toLowerCase() == query).toList();

    return matching.isNotEmpty ? matching : allSeeds;
  }
}

final placeSoundBiteRepositoryProvider = Provider<PlaceSoundBiteRepository>((ref) {
  final engine = ref.watch(placeSoundBiteEngineProvider);
  return PlaceSoundBiteRepository(engine: engine);
});

final placeSoundBitesProvider =
    FutureProvider.family<List<PlaceSoundBite>, String>((ref, placeId) async {
  final repo = ref.watch(placeSoundBiteRepositoryProvider);
  return repo.getPlaceSoundBites(placeId: placeId);
});
