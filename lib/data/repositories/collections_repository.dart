import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../models/collection_model.dart';
import '../services/supabase_service.dart';
import 'places_repository.dart';

final collectionsRepositoryProvider =
    NotifierProvider<CollectionsNotifier, List<CollectionModel>>(CollectionsNotifier.new);

class CollectionsNotifier extends Notifier<List<CollectionModel>> {
  static final List<CollectionModel> _defaultTashkentCollections = [
    CollectionModel(
      id: 'col-coffee-1',
      ownerId: '00000000-0000-0000-0000-000000000001',
      title: 'Tashkent Specialty Coffee & Bakes',
      description: 'The definitive shortlist for cardamom buns and natural process Ethiopian pour-overs.',
      audience: 'friends',
      isCollaborative: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      placeIds: const ['breadly', 'bnb', 'ecorn'],
    ),
    CollectionModel(
      id: 'col-night-1',
      ownerId: '00000000-0000-0000-0000-000000000001',
      title: 'Night Out: Vinyl & Sours',
      description: 'Intimate vibes, craft cocktails, and late-night vinyl sets.',
      audience: 'public',
      isCollaborative: false,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      placeIds: const ['steam', 'tims'],
    ),
  ];

  @override
  List<CollectionModel> build() {
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      Future.microtask(syncRemoteCollections);
      return [];
    }
    return List<CollectionModel>.from(_defaultTashkentCollections);
  }

  /// Syncs collections from Supabase `public.collections` (Phase 4.1).
  Future<void> syncRemoteCollections() async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final res = await SupabaseService.client
          .from('collections')
          .select('*, collection_items(place_id, places(slug))')
          .order('created_at', ascending: false);

      if (res.isNotEmpty) {
        final parsed = res
            .whereType<Map<String, dynamic>>()
            .map(CollectionModel.fromJson)
            .toList();
        state = parsed;
      } else {
        state = List<CollectionModel>.from(_defaultTashkentCollections);
      }
    } catch (e) {
      AppLogger.warn('CollectionsNotifier', 'Error syncing collections from Supabase', e);
      state = List<CollectionModel>.from(_defaultTashkentCollections);
    }
  }

  /// Creates a new custom collection.
  Future<CollectionModel> createCollection({
    required String title,
    String description = '',
    String audience = 'friends',
  }) async {
    final ownerId = SupabaseService.currentUser?.id ?? '00000000-0000-0000-0000-000000000001';
    final newCol = CollectionModel(
      id: 'col_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      title: title.trim(),
      description: description.trim(),
      audience: audience,
      createdAt: DateTime.now(),
      placeIds: const [],
    );

    state = [newCol, ...state];

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final inserted = await SupabaseService.client
            .from('collections')
            .insert({
              'owner_id': ownerId,
              'title': title.trim(),
              'description': description.trim(),
              'audience': audience,
            })
            .select()
            .single();

        final remoteId = inserted['id'] as String;
        state = [
          for (final c in state)
            if (c.id == newCol.id) c.copyWith(id: remoteId) else c,
        ];
      } catch (e) {
        AppLogger.error('CollectionsNotifier', 'Failed to create collection in Supabase', e);
      }
    }
    return newCol;
  }

  /// Adds a place to a custom collection.
  Future<void> addPlaceToCollection(String collectionId, String placeId) async {
    final canonical = PlacesRepository.resolveCanonicalId(placeId);
    state = [
      for (final c in state)
        if (c.id == collectionId && !c.placeIds.contains(canonical))
          c.copyWith(placeIds: [...c.placeIds, canonical])
        else
          c,
    ];

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final place = ref.read(placesRepositoryProvider).getPlaceById(canonical);
        final dbUuid = place?.canonicalUuid;
        if (dbUuid != null) {
          await SupabaseService.client.from('collection_items').insert({
            'collection_id': collectionId,
            'place_id': dbUuid,
            'added_by': SupabaseService.currentUser!.id,
          });
        }
      } catch (e) {
        AppLogger.warn('CollectionsNotifier', 'Error adding place to collection in Supabase', e);
      }
    }
  }

  /// Removes a place from a custom collection.
  Future<void> removePlaceFromCollection(String collectionId, String placeId) async {
    final canonical = PlacesRepository.resolveCanonicalId(placeId);
    state = [
      for (final c in state)
        if (c.id == collectionId)
          c.copyWith(placeIds: c.placeIds.where((id) => id != canonical && id != placeId).toList())
        else
          c,
    ];

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final place = ref.read(placesRepositoryProvider).getPlaceById(canonical);
        final dbUuid = place?.canonicalUuid;
        if (dbUuid != null) {
          await SupabaseService.client
              .from('collection_items')
              .delete()
              .eq('collection_id', collectionId)
              .eq('place_id', dbUuid);
        }
      } catch (e) {
        AppLogger.warn('CollectionsNotifier', 'Error removing place from collection in Supabase', e);
      }
    }
  }

  /// Deletes a custom collection.
  Future<void> deleteCollection(String collectionId) async {
    state = state.where((c) => c.id != collectionId).toList();
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client.from('collections').delete().eq('id', collectionId);
      } catch (e) {
        AppLogger.warn('CollectionsNotifier', 'Error deleting collection from Supabase', e);
      }
    }
  }
}
