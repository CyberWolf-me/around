import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/models/post_model.dart';
import 'package:around_app/data/repositories/posts_repository.dart';

void main() {
  group('Post Privacy & Audience Filtering Tests', () {
    late ProviderContainer container;
    late PostsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(postsRepositoryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial seed posts contain both friends-only and public posts', () {
      final posts = container.read(postsRepositoryProvider);
      expect(posts.isNotEmpty, isTrue);

      final hasFriendsOnly = posts.any((p) => p.audience == PostAudience.friends);
      final hasPublic = posts.any((p) => p.audience == PostAudience.public);

      expect(hasFriendsOnly, isTrue, reason: 'Must have friends-only posts seeded');
      expect(hasPublic, isTrue, reason: 'Must have public posts seeded');
    });

    test('getFriendsDrops only returns posts from followed friends or the current user', () {
      final followedIds = {'noor', 'teo'}; // Noor Haddad, Teo Vasquez
      final drops = notifier.getFriendsDrops(followedIds);

      for (final drop in drops) {
        final isFollowedOrSelf = followedIds.contains(drop.authorId) || drop.authorId == 'you';
        expect(
          isFollowedOrSelf,
          isTrue,
          reason: 'Post by author ${drop.authorId} (${drop.authorName}) should not appear in friends feed without following',
        );
      }
    });

    test('Stranger posts (e.g. mina if not followed) do not appear in friends feed', () {
      final followedOnlyNoor = {'noor'}; // Only follow Noor
      final drops = notifier.getFriendsDrops(followedOnlyNoor);

      final containsMina = drops.any((p) => p.authorId == 'mina');
      expect(containsMina, isFalse, reason: 'Unfollowed user mina must not appear in friends feed');
    });

    test('getDropsForPlace with friendsOnly=true filters out stranger drops', () {
      const placeId = 'kettle'; // Kettle & Loaf
      final followedIds = {'noor'}; // Only noor is followed

      final friendDrops = notifier.getDropsForPlace(
        placeId,
        friendsOnly: true,
        followedIds: followedIds,
      );

      for (final drop in friendDrops) {
        expect(
          followedIds.contains(drop.authorId) || drop.authorId == 'you',
          isTrue,
          reason: 'Only followed users or self can appear in friends drop tab',
        );
      }
    });

    test('getDropsForPlace with friendsOnly=false only returns public drops', () {
      const placeId = 'kettle';

      final publicDrops = notifier.getDropsForPlace(
        placeId,
        friendsOnly: false,
      );

      for (final drop in publicDrops) {
        expect(
          drop.audience,
          equals(PostAudience.public),
          reason: 'Public tab must strictly show PostAudience.public posts',
        );
      }
    });

    test('addDrop prepends a new drop to state correctly', () {
      final initialCount = container.read(postsRepositoryProvider).length;
      final newPost = PostModel(
        id: 'test-post-1',
        placeId: 'kettle',
        placeName: 'Kettle & Loaf',
        placeCategory: 'Bakery · Café',
        placeAddress: '14 Ledger Street',
        authorId: 'you',
        authorName: 'You',
        authorUsername: 'you',
        authorAvatar: 'YO',
        note: 'Testing fresh drop creation',
        mediaUrl: 'assets/kettle-hero.jpg',
        rating: 5,
        audience: PostAudience.friends,
        createdAt: DateTime.now(),
        tags: const ['cozy', 'espresso'],
      );

      notifier.addDrop(newPost);

      final updatedPosts = container.read(postsRepositoryProvider);
      expect(updatedPosts.length, equals(initialCount + 1));
      expect(updatedPosts.first.id, equals('test-post-1'));
      expect(updatedPosts.first.note, equals('Testing fresh drop creation'));
    });
  });
}
