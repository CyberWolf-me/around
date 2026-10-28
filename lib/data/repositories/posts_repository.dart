import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../../core/constants/app_colors.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

final postsRepositoryProvider = NotifierProvider<PostsNotifier, List<PostModel>>(PostsNotifier.new);

class PostsNotifier extends Notifier<List<PostModel>> {
  @override
  List<PostModel> build() {
    // Merge stored drops with initial seed drops
    final storedDrops = StorageService.getStoredDrops();
    if (storedDrops.isNotEmpty) {
      // Remove any stored drops that duplicate seed IDs, and prepend stored drops
      final storedIds = storedDrops.map((d) => d.id).toSet();
      final filteredSeeds = _initialSeedPosts.where((s) => !storedIds.contains(s.id)).toList();
      return [...storedDrops, ...filteredSeeds];
    }
    return _initialSeedPosts;
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
      note: 'The lavender matcha and warm sourdough here are unrivaled. Courtyard gets morning sun until 11am.',
      rating: 5,
      audience: PostAudience.friends,
      size: PostSize.hero,
      tags: const ['artisan sourdough', 'courtyard', 'specialty coffee'],
      mediaUrl: 'assets/bakery-counter.jpg',
      savesCount: 42,
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
      placeAddress: '24 Shota Rustaveli Street, Yakkasaray',
      note: 'Completed my full architectural render in one sitting. High-speed Wi-Fi, plugs at every booth, quiet corner.',
      rating: 5,
      audience: PostAudience.friends,
      size: PostSize.half,
      tags: const ['power outlets', 'study-friendly', 'chemex'],
      mediaUrl: 'assets/study-desk.jpg',
      savesCount: 68,
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
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  Future<void> publishDrop({
    required String placeId,
    required String placeName,
    required String placeCategory,
    required String placeAddress,
    required String note,
    int? rating,
    required PostAudience audience,
    List<String> tags = const [],
    String? mediaPath,
  }) async {
    final newPost = PostModel(
      id: 'drop_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'you',
      authorName: 'You (Explorer)',
      authorUsername: 'you',
      authorAvatar: 'YO',
      placeId: placeId,
      placeName: placeName,
      placeCategory: placeCategory,
      placeAddress: placeAddress,
      note: note,
      rating: rating,
      audience: audience,
      size: mediaPath != null ? PostSize.hero : PostSize.note,
      tags: tags,
      mediaUrl: mediaPath,
      savesCount: 0,
      createdAt: DateTime.now(),
    );

    // Update state
    final updatedList = [newPost, ...state];
    state = updatedList;

    // Persist to local storage
    await StorageService.persistDrops(updatedList);

    // Push to Supabase if connected
    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.from('posts').insert({
          'place_id': placeId,
          'note': note,
          'rating': rating,
          'audience': audience.name,
          'tags': tags,
          'media_url': mediaPath,
        });
      } catch (e) {
        debugPrint('[PostsRepository] Supabase push note: $e');
      }
    }
  }

  void addDrop(PostModel post) {
    state = [post, ...state];
    StorageService.persistDrops(state);
  }

  List<PostModel> getFriendsDrops(Set<String> followedIds) {
    return state.where((p) => p.authorId == 'you' || followedIds.contains(p.authorId)).toList();
  }

  List<PostModel> getPublicDrops() {
    return state.where((p) => p.audience == PostAudience.public).toList();
  }

  List<PostModel> getDropsForPlace(String placeId, {bool friendsOnly = false, Set<String>? followedIds}) {
    return state.where((p) {
      if (p.placeId != placeId) return false;
      if (friendsOnly) {
        return p.authorId == 'you' || (followedIds?.contains(p.authorId) ?? false);
      }
      return p.audience == PostAudience.public;
    }).toList();
  }
}
