import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../../core/constants/app_colors.dart';
import '../services/supabase_service.dart';

final postsRepositoryProvider = NotifierProvider<PostsNotifier, List<PostModel>>(PostsNotifier.new);

class PostsNotifier extends Notifier<List<PostModel>> {
  @override
  List<PostModel> build() => _initialSeedPosts;

  static final List<PostModel> _initialSeedPosts = [
    PostModel(
      id: 'd1',
      authorId: 'noor',
      authorName: 'Noor Haddad',
      authorUsername: 'noorh',
      authorAvatar: 'NH',
      placeId: 'kettle',
      placeName: 'Kettle & Loaf',
      placeCategory: 'Bakery · Café',
      placeAddress: '14 Ledger Street',
      note: 'Cortado is the good one here. The back room stays quiet until about eleven, then the whole street comes in at once.',
      rating: 5,
      audience: PostAudience.friends,
      size: PostSize.hero,
      tags: const ['quiet mornings', 'good cortado'],
      mediaUrl: 'assets/kettle-hero.jpg',
      savesCount: 12,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PostModel(
      id: 'd2',
      authorId: 'teo',
      authorName: 'Teo Vasquez',
      authorUsername: 'teovas',
      authorAvatar: 'TV',
      placeId: 'fern',
      placeName: 'The Fern Room',
      placeCategory: 'Study café',
      placeAddress: '2 Ostrander Avenue',
      note: 'Six hours on my thesis. Nobody looked at me once.',
      rating: 5,
      audience: PostAudience.friends,
      size: PostSize.half,
      tags: const ['outlets', 'long stays'],
      mediaUrl: 'assets/study-desk.jpg',
      savesCount: 31,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PostModel(
      id: 'd3',
      authorId: 'mina',
      authorName: 'Mina Osei',
      authorUsername: 'minaosei',
      authorAvatar: 'MO',
      placeId: 'sable',
      placeName: 'Sable Records',
      placeCategory: 'Record shop',
      placeAddress: '63 Kestrel Lane',
      note: 'Shellac bin is unreasonably deep.',
      rating: 5,
      audience: PostAudience.public,
      size: PostSize.half,
      tags: const ['crate digging'],
      mediaUrl: 'assets/records-crates.jpg',
      savesCount: 8,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    PostModel(
      id: 'd4',
      authorId: 'ari',
      authorName: 'Ari Lindqvist',
      authorUsername: 'arilind',
      authorAvatar: 'AL',
      placeId: 'castellan',
      placeName: 'Castellan',
      placeCategory: 'Wine bar',
      placeAddress: '8 Prine Row',
      note: 'Ask for something orange and cold and let them choose. It has never once gone badly.',
      rating: null,
      audience: PostAudience.friends,
      size: PostSize.note,
      tags: const ['date night'],
      mediaUrl: null,
      tint: AppColors.butter,
      savesCount: 19,
      createdAt: DateTime.now().subtract(const Duration(hours: 9)),
    ),
    PostModel(
      id: 'd5',
      authorId: 'priya',
      authorName: 'Priya Raman',
      authorUsername: 'priyar',
      authorAvatar: 'PR',
      placeId: 'volta',
      placeName: 'Volta Books',
      placeCategory: 'Bookshop',
      placeAddress: '21 Fenwick Walk',
      note: 'The €4 shelf by the door is a trap. I lost an hour.',
      rating: 4,
      audience: PostAudience.public,
      size: PostSize.half,
      tags: const ['€4 shelf'],
      mediaUrl: 'assets/bookshop-tall.jpg',
      savesCount: 24,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PostModel(
      id: 'd6',
      authorId: 'jonah',
      authorName: 'Jonah Beck',
      authorUsername: 'jonahb',
      authorAvatar: 'JB',
      placeId: 'noodle',
      placeName: 'Noodle Union',
      placeCategory: 'Ramen',
      placeAddress: '40 Halloway Street',
      note: 'Spicy miso, counter seat, out in twenty.',
      rating: 5,
      audience: PostAudience.public,
      size: PostSize.half,
      tags: const ['counter seats'],
      mediaUrl: 'assets/ramen.jpg',
      savesCount: 44,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PostModel(
      id: 'd7',
      authorId: 'mina',
      authorName: 'Mina Osei',
      authorUsername: 'minaosei',
      authorAvatar: 'MO',
      placeId: 'marigold',
      placeName: 'Marigold Patisserie',
      placeCategory: 'Patisserie',
      placeAddress: '5 Duarte Court',
      note: 'Kouign-amann sells out before ten. I have learned this the hard way four times now.',
      rating: 4,
      audience: PostAudience.friends,
      size: PostSize.wide,
      tags: const ['kouign-amann'],
      mediaUrl: 'assets/patisserie.jpg',
      savesCount: 37,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PostModel(
      id: 'd8',
      authorId: 'teo',
      authorName: 'Teo Vasquez',
      authorUsername: 'teovas',
      authorAvatar: 'TV',
      placeId: 'longtable',
      placeName: 'The Long Table',
      placeCategory: 'Work space',
      placeAddress: '11 Marrow Lane',
      note: 'Outlets at every single seat. I did not believe it either.',
      rating: null,
      audience: PostAudience.friends,
      size: PostSize.note,
      tags: const ['outlets'],
      mediaUrl: null,
      tint: AppColors.mint,
      savesCount: 15,
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
      authorName: 'Yusuf Okonjo',
      authorUsername: 'yusuf',
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

    // Optimistic client update
    state = [newPost, ...state];

    // Push to Supabase if initialized
    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.from('posts').insert({
          'place_id': placeId,
          'note': note,
          'rating': rating,
          'audience': audience.name,
          'tags': tags,
        });
      } catch (e) {
        debugPrint('[PostsRepository] Error syncing drop: $e');
      }
    }
  }

  void addDrop(PostModel post) {
    state = [post, ...state];
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
