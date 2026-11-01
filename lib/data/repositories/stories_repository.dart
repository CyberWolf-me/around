import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../models/story_model.dart';
import '../services/supabase_service.dart';
import 'places_repository.dart';

final storiesRepositoryProvider =
    NotifierProvider<StoriesRepository, List<StoryModel>>(StoriesRepository.new);

class StoriesRepository extends Notifier<List<StoryModel>> {
  static final List<StoryModel> _defaultTashkentStories = [
    StoryModel(
      id: 'story-breadly-1',
      authorId: '00000000-0000-0000-0000-000000000001',
      authorName: 'Kamila Rahimova',
      authorAvatar: 'KR',
      placeId: 'breadly',
      placeName: 'Breadly Bakery & Café',
      mediaUrl: 'assets/images/breadly.jpg',
      caption: 'Fresh cardamom buns just out of the oven! 🥐',
      audience: 'friends',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      expiresAt: DateTime.now().add(const Duration(hours: 22)),
    ),
    StoryModel(
      id: 'story-bnb-1',
      authorId: '00000000-0000-0000-0000-000000000002',
      authorName: 'Bobur Aliev',
      authorAvatar: 'BA',
      placeId: 'bnb',
      placeName: 'B&B Coffee House',
      mediaUrl: 'assets/images/bnb.jpg',
      caption: 'Morning pour-over batch brew on point ☕',
      audience: 'friends',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      expiresAt: DateTime.now().add(const Duration(hours: 20)),
    ),
    StoryModel(
      id: 'story-steam-1',
      authorId: '00000000-0000-0000-0000-000000000003',
      authorName: 'Rustam M.',
      authorAvatar: 'RM',
      placeId: 'steam',
      placeName: 'Steam Bar & Lounge',
      mediaUrl: 'assets/images/steam.jpg',
      caption: 'Vinyl session starts at 8pm tonight 🍸',
      audience: 'friends',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      expiresAt: DateTime.now().add(const Duration(hours: 19)),
    ),
    StoryModel(
      id: 'story-ecorn-1',
      authorId: '00000000-0000-0000-0000-000000000004',
      authorName: 'Dilnoza K.',
      authorAvatar: 'DK',
      placeId: 'ecorn',
      placeName: 'Ecorn Pastry Shop',
      mediaUrl: 'assets/images/ecorn.jpg',
      caption: 'Pistachio éclairs restocked! ✨',
      audience: 'public',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      expiresAt: DateTime.now().add(const Duration(hours: 18)),
    ),
  ];

  @override
  List<StoryModel> build() {
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      Future.microtask(syncRemoteStories);
      return [];
    }
    return List<StoryModel>.from(_defaultTashkentStories);
  }

  /// Syncs active 24h stories from Supabase `public.place_stories` (Phase 4.2).
  Future<void> syncRemoteStories() async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final nowIso = DateTime.now().toIso8601String();
      final res = await SupabaseService.client
          .from('place_stories')
          .select('*, profiles(full_name, username, avatar_initials), places(name, slug)')
          .gt('expires_at', nowIso)
          .order('created_at', ascending: false);

      if (res.isNotEmpty) {
        final parsed = res
            .whereType<Map<String, dynamic>>()
            .map(StoryModel.fromJson)
            .toList();
        state = parsed;
      } else {
        state = List<StoryModel>.from(_defaultTashkentStories);
      }
    } catch (e) {
      AppLogger.warn('StoriesRepository', 'Error syncing stories from Supabase', e);
      state = List<StoryModel>.from(_defaultTashkentStories);
    }
  }

  /// Creates a new 24h ephemeral story bound to caller's `auth.uid()`.
  Future<bool> createStory({
    required String placeId,
    required String mediaUrl,
    String caption = '',
    String audience = 'friends',
  }) async {
    final placesRepo = ref.read(placesRepositoryProvider);
    final place = placesRepo.getPlaceById(placeId);
    final canonicalSlug = place?.id ?? PlacesRepository.resolveCanonicalId(placeId);
    final placeName = place?.name ?? 'Tashkent Spot';

    final authorId = SupabaseService.currentUser?.id ?? '00000000-0000-0000-0000-000000000001';
    final newStory = StoryModel(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorName: 'You',
      authorAvatar: 'YOU',
      placeId: canonicalSlug,
      placeName: placeName,
      mediaUrl: mediaUrl,
      caption: caption,
      audience: audience,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    state = [newStory, ...state];

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final dbUuid = place?.canonicalUuid;
        if (dbUuid != null) {
          await SupabaseService.client.from('place_stories').insert({
            'author_id': authorId,
            'place_id': dbUuid,
            'media_url': mediaUrl,
            'caption': caption,
            'audience': audience,
            'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          });
        }
      } catch (e) {
        AppLogger.error('StoriesRepository', 'Failed to publish story to Supabase', e);
      }
    }
    return true;
  }

  /// Deletes a story by id.
  Future<void> deleteStory(String storyId) async {
    state = state.where((s) => s.id != storyId).toList();
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client.from('place_stories').delete().eq('id', storyId);
      } catch (e) {
        AppLogger.warn('StoriesRepository', 'Error deleting story from Supabase', e);
      }
    }
  }

  List<StoryModel> getStoriesForPlace(String placeId) {
    final canonical = PlacesRepository.resolveCanonicalId(placeId);
    return state.where((s) => s.placeId == canonical || s.placeId == placeId).toList();
  }
}
