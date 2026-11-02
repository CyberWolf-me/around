import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/errors/app_failure.dart';
import '../../core/services/app_logger.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import 'places_repository.dart';
import 'profiles_repository.dart';

final postsRepositoryProvider = NotifierProvider<PostsNotifier, List<PostModel>>(PostsNotifier.new);

class PostsNotifier extends Notifier<List<PostModel>> {
  final List<DateTime> _recentPublishTimestamps = [];

  @override
  List<PostModel> build() {
    final storedDrops = StorageService.getStoredDrops();
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      Future.microtask(syncRemoteFeed);
      if (storedDrops.isNotEmpty) return storedDrops;
      return [];
    }
    if (storedDrops.isNotEmpty) {
      final storedIds = storedDrops.map((d) => d.id).toSet();
      final filteredSeeds = _initialSeedPosts.where((s) => !storedIds.contains(s.id)).toList();
      return [...storedDrops, ...filteredSeeds];
    }
    return _initialSeedPosts;
  }

  bool _isCurrentUserAuthor(String authorId) {
    if (authorId == 'you') return true;
    final currentProfileId = ref.read(currentProfileProvider).id;
    if (authorId == currentProfileId) return true;
    final authUid = SupabaseService.currentUser?.id;
    return authUid != null && authorId == authUid;
  }

  /// Calls the hardened SECURITY INVOKER `get_friends_feed` PostGIS RPC (`00003` & `00005`)
  /// when authenticated with Supabase and merges remote drops into state (MIG-02 aligned).
  Future<void> syncRemoteFeed() async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final response = await SupabaseService.client.rpc(
        'get_friends_feed',
        params: {'page_limit': 30, 'page_offset': 0},
      );
      if (response is List && response.isNotEmpty) {
        final remotePosts = response
            .whereType<Map<String, dynamic>>()
            .map((row) => PostModel.fromJson({
                  'id': row['post_id']?.toString() ?? '',
                  'author_id': row['author_id']?.toString() ?? '',
                  'author_name': (row['author_name'] ?? row['author_full_name'])?.toString() ?? 'Friend',
                  'author_username': row['author_username']?.toString() ?? 'friend',
                  'author_avatar': (row['author_avatar'] ?? row['author_avatar_url'])?.toString() ?? 'FR',
                  'place_id': (row['place_slug'] ?? row['place_id'])?.toString() ?? 'breadly',
                  'place_name': row['place_name']?.toString() ?? 'Tashkent Spot',
                  'place_category': row['place_category']?.toString() ?? 'Café',
                  'place_address': (row['place_address'] ?? row['place_street_address'])?.toString() ?? 'Tashkent',
                  'note': row['note']?.toString() ?? '',
                  'rating': row['rating'],
                  'audience': row['audience']?.toString() ?? 'friends',
                  'size': row['size']?.toString() ?? 'hero',
                  'tags': row['tags'] ?? const <String>[],
                  'media_url': (row['media_url'] ?? row['primary_media_url'])?.toString(),
                  'saves_count': row['saves_count'] ?? 0,
                  'created_at': row['created_at']?.toString(),
                }))
            .toList();
        final existingIds = state.map((p) => p.id).toSet();
        final newRemotes = remotePosts.where((r) => !existingIds.contains(r.id)).toList();
        if (newRemotes.isNotEmpty) {
          state = [...newRemotes, ...state];
          await StorageService.persistDrops(state);
        }
      }
    } catch (e) {
      AppLogger.warn('PostsRepository', 'Remote get_friends_feed sync skipped', e);
    }
  }

  bool _hasMoreRemoteDrops = true;
  bool get hasMoreRemoteDrops => _hasMoreRemoteDrops;

  /// Loads the next page of friends drops via keyset cursor pagination (`P8-01`).
  /// Uses (createdAt, id) of the oldest loaded drop as deterministic cursor.
  Future<int> loadMoreFriendsFeed({int pageSize = 20}) async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return 0;
    if (!_hasMoreRemoteDrops) return 0;

    try {
      // Find the oldest remote/feed drop in the current state to use as the keyset cursor
      final sorted = List<PostModel>.from(state)
        ..sort((a, b) {
          final comp = b.createdAt.compareTo(a.createdAt);
          if (comp != 0) return comp;
          return b.id.compareTo(a.id);
        });

      final oldestDrop = sorted.isNotEmpty ? sorted.last : null;

      final Map<String, dynamic> params = {
        'page_limit': pageSize,
        'page_offset': 0,
      };

      if (oldestDrop != null) {
        params['p_cursor_created_at'] = oldestDrop.createdAt.toIso8601String();
        if (oldestDrop.id.contains('-')) {
          params['p_cursor_id'] = oldestDrop.id;
        }
      }

      final response = await SupabaseService.client.rpc(
        'get_friends_feed',
        params: params,
      );

      if (response is List) {
        if (response.isEmpty || response.length < pageSize) {
          _hasMoreRemoteDrops = false;
        }

        final remotePosts = response
            .whereType<Map<String, dynamic>>()
            .map((row) => PostModel.fromJson({
                  'id': row['post_id']?.toString() ?? '',
                  'author_id': row['author_id']?.toString() ?? '',
                  'author_name': (row['author_name'] ?? row['author_full_name'])?.toString() ?? 'Friend',
                  'author_username': row['author_username']?.toString() ?? 'friend',
                  'author_avatar': (row['author_avatar'] ?? row['author_avatar_url'])?.toString() ?? 'FR',
                  'place_id': (row['place_slug'] ?? row['place_id'])?.toString() ?? 'breadly',
                  'place_name': row['place_name']?.toString() ?? 'Tashkent Spot',
                  'place_category': row['place_category']?.toString() ?? 'Café',
                  'place_address': (row['place_address'] ?? row['place_street_address'])?.toString() ?? 'Tashkent',
                  'note': row['note']?.toString() ?? '',
                  'rating': row['rating'],
                  'audience': row['audience']?.toString() ?? 'friends',
                  'size': row['size']?.toString() ?? 'hero',
                  'tags': row['tags'] ?? const <String>[],
                  'media_url': (row['media_url'] ?? row['primary_media_url'])?.toString(),
                  'saves_count': row['saves_count'] ?? 0,
                  'created_at': row['created_at']?.toString(),
                }))
            .toList();

        final existingIds = state.map((p) => p.id).toSet();
        final newDrops = remotePosts.where((r) => !existingIds.contains(r.id)).toList();

        if (newDrops.isNotEmpty) {
          state = [...state, ...newDrops];
          await StorageService.persistDrops(state);
        }

        return newDrops.length;
      }
      return 0;
    } catch (e) {
      AppLogger.warn('PostsRepository', 'loadMoreFriendsFeed keyset pagination skipped', e);
      return 0;
    }
  }

  /// Fetches authorized Friends & Public drops for a specific venue from Supabase (`INT-02` Journey D).
  Future<void> syncRemotePlaceDrops(String placeId) async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final canonical = PlacesRepository.resolveCanonicalId(placeId);
      final dbUuid = ref.read(placesRepositoryProvider).getPlaceById(canonical)?.canonicalUuid;
      if (dbUuid == null) return;

      final rows = await SupabaseService.client
          .from('posts')
          .select('*, profiles(username, full_name, avatar_url), post_media(media_url, is_primary)')
          .eq('place_id', dbUuid)
          .eq('is_quarantined', false)
          .order('created_at', ascending: false)
          .limit(30);

      if (rows.isNotEmpty) {
        final placeModel = ref.read(placesRepositoryProvider).getPlaceById(canonical);
        final fetched = <PostModel>[];
        for (final raw in rows.whereType<Map<String, dynamic>>()) {
          final prof = raw['profiles'] is Map ? Map<String, dynamic>.from(raw['profiles'] as Map) : <String, dynamic>{};
          final mediaList = raw['post_media'] is List ? (raw['post_media'] as List) : const [];
          String? mediaUrl;
          if (mediaList.isNotEmpty && mediaList.first is Map) {
            mediaUrl = (mediaList.first as Map)['media_url']?.toString();
          }
          fetched.add(PostModel.fromJson({
            'id': raw['id']?.toString() ?? '',
            'author_id': raw['author_id']?.toString() ?? '',
            'author_name': prof['full_name']?.toString() ?? 'Explorer',
            'author_username': prof['username']?.toString() ?? 'explorer',
            'author_avatar': prof['avatar_url']?.toString() ?? 'EX',
            'place_id': canonical,
            'place_name': placeModel?.name ?? 'Tashkent Spot',
            'place_category': placeModel?.category ?? 'Café',
            'place_address': placeModel?.streetAddress ?? 'Tashkent',
            'note': raw['note']?.toString() ?? '',
            'rating': raw['rating'],
            'audience': raw['audience']?.toString() ?? 'public',
            'size': raw['size']?.toString() ?? 'half',
            'tags': raw['tags'] ?? const <String>[],
            'media_url': mediaUrl,
            'saves_count': raw['saves_count'] ?? 0,
            'reactions_count': raw['reactions_count'] ?? 0,
            'created_at': raw['created_at']?.toString(),
          }));
        }
        final existingIds = state.map((p) => p.id).toSet();
        final newItems = fetched.where((f) => !existingIds.contains(f.id)).toList();
        if (newItems.isNotEmpty) {
          state = [...newItems, ...state];
          await StorageService.persistDrops(state);
        }
      }
    } catch (e) {
      AppLogger.warn('PostsRepository', 'Remote place drops sync skipped', e);
    }
  }

  static final List<PostModel> _initialSeedPosts = [
    PostModel(
      id: 'drop_tash_1',
      authorId: 'kamila',
      authorName: 'Kamila Rahimova',
      authorUsername: 'kamilar',
      authorAvatar: 'KR',
      placeId: 'breadly',
      placeName: 'Breadly Bakery & Café',
      placeCategory: 'Bakery · Specialty Café',
      placeAddress: '24 Taras Shevchenko Street, Mirabad',
      note: 'The lavender matcha and warm sourdough here are a morning ritual. Courtyard gets sun until 11am.',
      rating: 5,
      audience: PostAudience.friends,
      size: PostSize.hero,
      tags: const ['artisan sourdough', 'courtyard', 'specialty coffee'],
      mediaUrl: 'assets/bakery-counter.jpg',
      savesCount: 42,
      reactionsCount: 18,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PostModel(
      id: 'drop_tash_2',
      authorId: 'bekzod',
      authorName: 'Bekzod Alimov',
      authorUsername: 'bekalimov',
      authorAvatar: 'BA',
      placeId: 'bnb',
      placeName: 'B&B Coffee House',
      placeCategory: 'Study Café · Roastery',
      placeAddress: '18 Shota Rustaveli Street, Yakkasaray',
      note: 'Completed my full architectural render in one sitting. High-speed Wi-Fi, plugs at every booth, quiet corner.',
      rating: 5,
      audience: PostAudience.friends,
      size: PostSize.half,
      tags: const ['power outlets', 'study-friendly', 'chemex'],
      mediaUrl: 'assets/study-desk.jpg',
      savesCount: 68,
      reactionsCount: 24,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    PostModel(
      id: 'drop_tash_3',
      authorId: 'aziza',
      authorName: 'Aziza Tursunova',
      authorUsername: 'azizatur',
      authorAvatar: 'AT',
      placeId: 'ecorn',
      placeName: 'Ecorn Patisserie',
      placeCategory: 'French Patisserie · Bistro',
      placeAddress: '32 Amir Timur Avenue, Yunusabad',
      note: 'Pistachio eclair here is legitimate Parisian level. Second-floor balcony overlooking Amir Timur Ave.',
      rating: 5,
      audience: PostAudience.public,
      size: PostSize.half,
      tags: const ['pistachio eclair', 'terrace', 'date spot'],
      mediaUrl: 'assets/patisserie.jpg',
      savesCount: 53,
      reactionsCount: 19,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    PostModel(
      id: 'drop_tash_4',
      authorId: 'jasur',
      authorName: 'Jasur Kadirov',
      authorUsername: 'jasur_k',
      authorAvatar: 'JK',
      placeId: 'chorsu',
      placeName: 'Chorsu Milliy Taomlar',
      placeCategory: 'Uzbek Cuisine · Open Kitchen',
      placeAddress: 'Beruni Avenue, Chorsu Old City',
      note: 'Come right at 11:30 AM when the Wedding Osh comes off the fire. Saffron rice, tender lamb, quail eggs.',
      rating: 5,
      audience: PostAudience.public,
      size: PostSize.hero,
      tags: const ['wedding plov', 'tandir somsa', 'authentic'],
      mediaUrl: 'assets/street.jpg',
      savesCount: 114,
      reactionsCount: 42,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    PostModel(
      id: 'drop_tash_5',
      authorId: 'diyor',
      authorName: 'Diyor Usmanov',
      authorUsername: 'diyor_u',
      authorAvatar: 'DU',
      placeId: 'tims',
      placeName: 'Tim’s Coffee & Roastery',
      placeCategory: 'Specialty Roastery',
      placeAddress: '40 Taras Shevchenko Street, Mirabad',
      note: 'Natural processed Ethiopian batch brew is fruity and super clean. Roaster running right behind the bar.',
      rating: 5,
      audience: PostAudience.friends,
      size: PostSize.note,
      tags: const ['single origin', 'v60 pour-over', 'tech crowd'],
      mediaUrl: null,
      tint: AppColors.butter,
      savesCount: 29,
      reactionsCount: 11,
      createdAt: DateTime.now().subtract(const Duration(hours: 11)),
    ),
    PostModel(
      id: 'drop_tash_6',
      authorId: 'madina',
      authorName: 'Madina Karimova',
      authorUsername: 'madinakar',
      authorAvatar: 'MK',
      placeId: 'centralpark',
      placeName: 'Central Park (Mirzo Ulugbek)',
      placeCategory: 'Park · Green Promenade',
      placeAddress: '21 Movaraunnahr Street',
      note: 'Sunset light reflecting off the pond. Picked up iced matcha at the east gate kiosk.',
      rating: 5,
      audience: PostAudience.friends,
      size: PostSize.wide,
      tags: const ['evening strolls', 'lake', 'matcha kiosk'],
      mediaUrl: 'assets/window-girl.jpg',
      savesCount: 77,
      reactionsCount: 29,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PostModel(
      id: 'drop_tash_7',
      authorId: 'rustam',
      authorName: 'Rustam Mirzaev',
      authorUsername: 'rustamm',
      authorAvatar: 'RM',
      placeId: 'steam',
      placeName: 'Steam Bar & Lounge',
      placeCategory: 'Cocktail Lounge · Vinyl Bar',
      placeAddress: '29 Nukus Street, Mirabad',
      note: 'Ask for the pomegranate smoked sour. Vinyl DJ sets start at 9.',
      rating: 4,
      audience: PostAudience.public,
      size: PostSize.half,
      tags: const ['craft cocktails', 'vinyl DJ', 'nightlife'],
      mediaUrl: 'assets/wine-wide.jpg',
      savesCount: 39,
      reactionsCount: 14,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PostModel(
      id: 'drop_tash_8',
      authorId: 'shakhlo',
      authorName: 'Shakhlo Nazarova',
      authorUsername: 'shakhlo_n',
      authorAvatar: 'SN',
      placeId: 'kitobxon',
      placeName: 'Kitobxon Book Café',
      placeCategory: 'Bookstore · Literary Café',
      placeAddress: '11 Alisher Navoi Avenue',
      note: 'The quiet back room with the velvet armchairs is Tashkent’s best kept secret for reading.',
      rating: 5,
      audience: PostAudience.public,
      size: PostSize.note,
      tags: const ['bookstore', 'quiet nooks', 'aeropress'],
      mediaUrl: null,
      tint: AppColors.mint,
      savesCount: 61,
      reactionsCount: 27,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  /// Enforces rate limiting (max 10 drops / 5 minutes) and input validation (SEC-08).
  Future<AppFailure?> publishDrop({
    required String placeId,
    required String placeName,
    required String placeCategory,
    required String placeAddress,
    required String note,
    int? rating,
    required PostAudience audience,
    List<String> tags = const [],
    String? mediaPath,
    Color? tint,
  }) async {
    final now = DateTime.now();
    _recentPublishTimestamps.removeWhere((t) => now.difference(t).inMinutes >= 5);
    if (_recentPublishTimestamps.length >= 10) {
      return const AppFailure('Rate limit exceeded: Maximum 10 drops per 5 minutes.', code: 'RATE_LIMITED');
    }

    final validationError = AppLogger.validateDropInput(note: note, tags: tags);
    if (validationError != null) return validationError;

    if (mediaPath != null) {
      final imgError = AppLogger.validateImagePath(mediaPath);
      if (imgError != null) return imgError;
    }

    _recentPublishTimestamps.add(now);
    final profile = ref.read(currentProfileProvider);
    final canonicalPlaceId = PlacesRepository.resolveCanonicalId(placeId);

    final newPost = PostModel(
      id: 'drop_${now.millisecondsSinceEpoch}',
      authorId: profile.id,
      authorName: profile.fullName,
      authorUsername: profile.username,
      authorAvatar: profile.initials,
      placeId: canonicalPlaceId,
      placeName: placeName,
      placeCategory: placeCategory,
      placeAddress: placeAddress,
      note: note.trim(),
      rating: rating,
      audience: audience,
      size: mediaPath != null ? PostSize.hero : PostSize.note,
      tags: tags,
      mediaUrl: mediaPath,
      tint: tint ?? (mediaPath == null ? AppColors.butter : null),
      savesCount: 0,
      reactionsCount: 0,
      createdAt: now,
    );

    final updatedList = [newPost, ...state];
    state = updatedList;
    await StorageService.persistDrops(updatedList);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      UploadedMediaResult? uploadedMedia;
      try {
        final placeModel = ref.read(placesRepositoryProvider).getPlaceById(canonicalPlaceId);
        final dbPlaceUuid = placeModel?.canonicalUuid;
        if (dbPlaceUuid != null) {
          final insertedPost = await SupabaseService.client
              .from('posts')
              .insert({
                'author_id': SupabaseService.currentUser!.id,
                'place_id': dbPlaceUuid,
                'note': note.trim(),
                'rating': rating,
                'audience': audience.name,
                'size': newPost.size.name,
                'tags': tags,
              })
              .select('id')
              .single();

          if (mediaPath != null && insertedPost['id'] != null) {
            uploadedMedia = await SupabaseService.uploadDropMediaResult(mediaPath);
            await SupabaseService.client.from('post_media').insert({
              'post_id': insertedPost['id'],
              'storage_path': uploadedMedia?.storagePath ?? mediaPath,
              'media_url': uploadedMedia?.mediaUrl ?? mediaPath,
              'is_primary': true,
            });
          }
        }
      } catch (e) {
        if (uploadedMedia != null) {
          await SupabaseService.removeOrphanedMedia(uploadedMedia.storagePath);
        }
        AppLogger.error('PostsRepository', 'Supabase drop sync failed', e);
      }
    }
    return null;
  }

  /// Edits an existing Drop owned by the current user (Phase 3.3 — Experiences Domain).
  Future<AppFailure?> editDrop({
    required String postId,
    required String note,
    int? rating,
    PostAudience? audience,
    List<String>? tags,
  }) async {
    final target = state.where((p) => p.id == postId).firstOrNull;
    if (target == null) {
      return const AppFailure('Drop not found.', code: 'NOT_FOUND');
    }
    if (!_isCurrentUserAuthor(target.authorId)) {
      return const AppFailure('You can only edit your own drops.', code: 'FORBIDDEN');
    }

    final validationError = AppLogger.validateDropInput(
      note: note,
      tags: tags ?? target.tags,
    );
    if (validationError != null) return validationError;

    state = state.map<PostModel>((p) {
      if (p.id != postId) return p;
      return p.copyWith(
        note: note.trim(),
        rating: rating ?? p.rating,
        audience: audience ?? p.audience,
        tags: tags ?? p.tags,
      );
    }).toList();
    await StorageService.persistDrops(state);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client
            .from('posts')
            .update({
              'note': note.trim(),
              if (rating != null) 'rating': rating,
              if (audience != null) 'audience': audience.name,
              if (tags != null) 'tags': tags,
            })
            .eq('id', postId)
            .eq('author_id', SupabaseService.currentUser!.id);
      } catch (e) {
        AppLogger.warn('PostsRepository', 'Supabase editDrop sync skipped', e);
      }
    }
    return null;
  }

  /// Deletes a Drop owned by the current user (Phase 3.3 — Experiences Domain).
  Future<bool> deleteDrop(String postId) async {
    final target = state.where((p) => p.id == postId).firstOrNull;
    if (target == null) return false;
    if (!_isCurrentUserAuthor(target.authorId)) {
      return false;
    }

    state = state.where((p) => p.id != postId).toList();
    await StorageService.persistDrops(state);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client
            .from('posts')
            .delete()
            .eq('id', postId)
            .eq('author_id', SupabaseService.currentUser!.id);
      } catch (e) {
        AppLogger.warn('PostsRepository', 'Supabase deleteDrop sync skipped', e);
      }
    }
    return true;
  }

  /// Toggles a reaction (`heart`, `fire`, `bookmark_nod`, `coffee`) on an authorized Drop (Phase 4.3).
  Future<void> reactToPost(String postId, {String reaction = 'heart'}) async {
    final idx = state.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final currentPost = state[idx];
    final isAlreadyActive = currentPost.userReaction == reaction;

    final newReactionsCount = isAlreadyActive
        ? (currentPost.reactionsCount > 0 ? currentPost.reactionsCount - 1 : 0)
        : currentPost.reactionsCount + 1;

    // Optimistic state update: update reactionsCount, leaving savesCount untouched
    state = [
      for (final p in state)
        if (p.id == postId)
          p.copyWith(
            userReaction: isAlreadyActive ? null : reaction,
            clearUserReaction: isAlreadyActive,
            reactionsCount: newReactionsCount,
          )
        else
          p,
    ];
    await StorageService.persistDrops(state);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        if (isAlreadyActive) {
          await SupabaseService.client
              .from('post_reactions')
              .delete()
              .eq('post_id', postId)
              .eq('user_id', SupabaseService.currentUser!.id)
              .eq('reaction', reaction);
        } else {
          await SupabaseService.client.from('post_reactions').upsert({
            'post_id': postId,
            'user_id': SupabaseService.currentUser!.id,
            'reaction': reaction,
          });
        }
      } catch (e) {
        AppLogger.warn('PostsRepository', 'Supabase post_reactions sync failed, rolling back', e);
        // Rollback on failure
        state = [
          for (final p in state)
            if (p.id == postId) currentPost else p,
        ];
        await StorageService.persistDrops(state);
      }
    }
  }

  final Map<String, List<CommentModel>> _commentsCache = {};

  /// Fetches comments for an authorized Drop (Phase 4.3).
  Future<List<CommentModel>> fetchCommentsForPost(String postId) async {
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final res = await SupabaseService.client
            .from('post_comments')
            .select('*, profiles(full_name, username, avatar_initials)')
            .eq('post_id', postId)
            .order('created_at', ascending: true);

        if (res.isNotEmpty) {
          final comments = res
              .whereType<Map<String, dynamic>>()
              .map(CommentModel.fromJson)
              .toList();
          _commentsCache[postId] = comments;
          return comments;
        }
      } catch (e) {
        AppLogger.warn('PostsRepository', 'Supabase post_comments fetch skipped', e);
      }
    }
    return _commentsCache[postId] ?? [];
  }

  /// Adds a comment (1–300 chars) to an authorized Drop with optimistic state & rollback (Phase 4.3).
  Future<AppFailure?> addCommentToPost(String postId, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.length > 300) {
      return const AppFailure('Comment must be between 1 and 300 characters.', code: 'INVALID_COMMENT');
    }

    final authorId = SupabaseService.currentUser?.id ?? '00000000-0000-0000-0000-000000000001';
    final newComment = CommentModel(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorId: authorId,
      authorName: 'You',
      authorAvatar: 'YOU',
      body: trimmed,
      createdAt: DateTime.now(),
    );

    final current = _commentsCache[postId] ?? [];
    _commentsCache[postId] = [...current, newComment];

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client.from('post_comments').insert({
          'post_id': postId,
          'author_id': authorId,
          'body': trimmed,
        });
      } catch (e) {
        AppLogger.warn('PostsRepository', 'Supabase post_comments sync failed, rolling back', e);
        _commentsCache[postId] = current;
        return const AppFailure('Failed to post comment. Please try again.', code: 'COMMENT_POST_FAILED');
      }
    }
    return null;
  }

  /// Increments report count on a post and automatically quarantines it at 3+ reports.
  Future<bool> reportPost(String postId, String reason) async {
    final totalReports = await StorageService.addReport({
      'target_type': 'post',
      'target_id': postId,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client.from('reports').insert({
          'reporter_id': SupabaseService.currentUser!.id,
          'target_type': 'post',
          'target_id': postId,
          'reason': reason,
        });
      } catch (e) {
        AppLogger.warn('PostsRepository', 'Supabase report sync skipped', e);
      }
    }

    var quarantinedNow = false;
    state = state.map((p) {
      if (p.id != postId) return p;
      final newCount = totalReports > p.reportsCount ? totalReports : p.reportsCount + 1;
      final shouldQuarantine = newCount >= 3;
      if (shouldQuarantine) quarantinedNow = true;
      return p.copyWith(reportsCount: newCount, isQuarantined: shouldQuarantine);
    }).toList();
    await StorageService.persistDrops(state);
    return quarantinedNow;
  }

  void addDrop(PostModel post) {
    state = [post, ...state];
    StorageService.persistDrops(state);
  }

  List<PostModel> getFriendsDrops(Set<String> acceptedFriendIds, {Set<String>? blockedIds}) {
    final blocked = blockedIds ?? ref.read(blockedUsersProvider);
    return state.where((p) {
      if (p.isQuarantined) return false;
      if (blocked?.contains(p.authorId) ?? false) return false;
      return _isCurrentUserAuthor(p.authorId) || acceptedFriendIds.contains(p.authorId);
    }).toList();
  }

  List<PostModel> getPublicDrops({Set<String>? blockedIds}) {
    final blocked = blockedIds ?? ref.read(blockedUsersProvider);
    return state.where((p) {
      if (p.isQuarantined) return false;
      if (blocked?.contains(p.authorId) ?? false) return false;
      return p.audience == PostAudience.public;
    }).toList();
  }

  List<PostModel> getDropsForPlace(
    String placeId, {
    bool friendsOnly = false,
    Set<String>? followedIds,
    Set<String>? blockedIds,
  }) {
    final canonicalTarget = PlacesRepository.resolveCanonicalId(placeId);
    final blocked = blockedIds ?? ref.read(blockedUsersProvider);
    return state.where((p) {
      if (p.isQuarantined) return false;
      if (PlacesRepository.resolveCanonicalId(p.placeId) != canonicalTarget) return false;
      if (blocked?.contains(p.authorId) ?? false) return false;
      if (friendsOnly) {
        return _isCurrentUserAuthor(p.authorId) || (followedIds?.contains(p.authorId) ?? false);
      }
      return p.audience == PostAudience.public;
    }).toList();
  }
}
