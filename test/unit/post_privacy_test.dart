import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/app_logger.dart';
import 'package:around_app/core/services/exif_sanitizer.dart';
import 'package:around_app/data/models/post_model.dart';
import 'package:around_app/data/repositories/posts_repository.dart';
import 'package:around_app/data/repositories/profiles_repository.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  group('Post Privacy, Mutual Friendship & Auto-Quarantine Tests', () {
    late ProviderContainer container;
    late PostsNotifier notifier;

    setUp(() async {
      await StorageService.clearAll();
      container = ProviderContainer();
      notifier = container.read(postsRepositoryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial seed posts contain both friends-only and public Tashkent posts', () {
      final posts = container.read(postsRepositoryProvider);
      expect(posts.length, greaterThanOrEqualTo(8));

      final hasFriendsOnly = posts.any((p) => p.audience == PostAudience.friends);
      final hasPublic = posts.any((p) => p.audience == PostAudience.public);

      expect(hasFriendsOnly, isTrue, reason: 'Must have friends-only posts seeded');
      expect(hasPublic, isTrue, reason: 'Must have public posts seeded');
    });

    test('Default followedFriendsProvider matches seeded Tashkent friend authors (non-empty feed)', () {
      final defaultFollowed = container.read(followedFriendsProvider);
      final drops = notifier.getFriendsDrops(defaultFollowed);

      expect(drops.isNotEmpty, isTrue, reason: 'Friends feed must not be empty with default followed friends');
      for (final drop in drops) {
        final isFollowedOrSelf = defaultFollowed.contains(drop.authorId) || drop.authorId == 'you';
        expect(isFollowedOrSelf, isTrue);
      }
    });

    test('Pending outgoing friend request does NOT unlock friends-only drops until accepted (SEC-04)', () async {
      final relNotifier = container.read(friendshipStatusesProvider.notifier);
      // Rustam is not initially a friend
      expect(relNotifier.getRelation('rustam'), equals(FriendshipRelation.none));

      // Send friend request -> transitions to pendingOutgoing, NOT accepted
      await relNotifier.requestOrToggleFriendship('rustam');
      expect(relNotifier.getRelation('rustam'), equals(FriendshipRelation.pendingOutgoing));
      expect(container.read(followedFriendsProvider).contains('rustam'), isFalse);

      // Shakhlo has allowFriendRequests == false -> request is rejected
      final msg = await relNotifier.requestOrToggleFriendship('shakhlo');
      expect(msg, contains('disabled incoming friend requests'));
      expect(relNotifier.getRelation('shakhlo'), equals(FriendshipRelation.none));
    });

    test('3-report auto-quarantine removes reported drop from feeds (PRIVACY_AND_SAFETY_GOVERNANCE)', () async {
      const targetPostId = 'drop_tash_1';
      expect(
        notifier.getFriendsDrops({'kamila'}).any((p) => p.id == targetPostId),
        isTrue,
      );

      await notifier.reportPost(targetPostId, 'Spam 1');
      await notifier.reportPost(targetPostId, 'Spam 2');
      final quarantined = await notifier.reportPost(targetPostId, 'Spam 3');

      expect(quarantined, isTrue);
      expect(
        notifier.getFriendsDrops({'kamila'}).any((p) => p.id == targetPostId),
        isFalse,
        reason: 'Quarantined post must be excluded from Friends Feed',
      );
    });

    test('canViewMemberVisitHistory enforces Keep my visits private (hideVisitsHistory)', () {
      // Diyor has hideVisitsHistory = true
      expect(
        canViewMemberVisitHistory(
          viewerId: 'you',
          targetUserId: 'diyor',
          targetHideVisitsHistory: true,
          areMutualFriends: true,
        ),
        isFalse,
      );

      // User can always view their own history
      expect(
        canViewMemberVisitHistory(
          viewerId: 'diyor',
          targetUserId: 'diyor',
          targetHideVisitsHistory: true,
          areMutualFriends: false,
        ),
        isTrue,
      );
    });

    test('Blocked users are strictly excluded from both friends feed and public drops', () {
      final followed = {'kamila', 'bekzod', 'aziza'};
      final blocked = {'bekzod', 'aziza'};

      final friendDrops = notifier.getFriendsDrops(followed, blockedIds: blocked);
      expect(friendDrops.isNotEmpty, isTrue);
      expect(friendDrops.any((p) => p.authorId == 'bekzod'), isFalse);
      expect(friendDrops.any((p) => p.authorId == 'aziza'), isFalse);

      final publicDrops = notifier.getPublicDrops(blockedIds: blocked);
      expect(publicDrops.isNotEmpty, isTrue);
      expect(publicDrops.any((p) => p.authorId == 'aziza'), isFalse);
    });

    test('getDropsForPlace with friendsOnly=true returns non-empty friend drops for Breadly', () {
      const placeId = 'breadly';
      final followedIds = {'kamila'};

      final friendDrops = notifier.getDropsForPlace(
        placeId,
        friendsOnly: true,
        followedIds: followedIds,
      );

      expect(friendDrops.isNotEmpty, isTrue);
      for (final drop in friendDrops) {
        expect(followedIds.contains(drop.authorId) || drop.authorId == 'you', isTrue);
      }
    });

    test('getDropsForPlace with friendsOnly=false strictly returns public drops', () {
      const placeId = 'ecorn';

      final publicDrops = notifier.getDropsForPlace(
        placeId,
        friendsOnly: false,
      );

      expect(publicDrops.isNotEmpty, isTrue);
      for (final drop in publicDrops) {
        expect(drop.audience, equals(PostAudience.public));
      }
    });

    test('addDrop, editDrop, and deleteDrop enforce ownership and update state (Phase 3.3)', () async {
      final initialCount = container.read(postsRepositoryProvider).length;
      final newPost = PostModel(
        id: 'test-post-1',
        placeId: 'breadly',
        placeName: 'Breadly Bakery & Café',
        placeCategory: 'Bakery · Specialty Café',
        placeAddress: '24 Taras Shevchenko Street',
        authorId: 'you',
        authorName: 'You',
        authorUsername: 'you',
        authorAvatar: 'YO',
        note: 'Testing fresh drop creation',
        mediaUrl: 'assets/bakery-counter.jpg',
        rating: 5,
        audience: PostAudience.friends,
        createdAt: DateTime.now(),
        tags: const ['sourdough', 'matcha'],
      );

      notifier.addDrop(newPost);
      expect(container.read(postsRepositoryProvider).length, equals(initialCount + 1));

      // Edit own drop
      final editErr = await notifier.editDrop(
        postId: 'test-post-1',
        note: 'Updated sourdough review note',
        audience: PostAudience.public,
      );
      expect(editErr, isNull);
      final edited = container.read(postsRepositoryProvider).firstWhere((p) => p.id == 'test-post-1');
      expect(edited.note, equals('Updated sourdough review note'));
      expect(edited.audience, equals(PostAudience.public));

      // Cannot edit another user's drop
      final forbiddenErr = await notifier.editDrop(
        postId: 'drop_tash_1',
        note: 'Attempted tamper',
      );
      expect(forbiddenErr, isNotNull);
      expect(forbiddenErr!.code, equals('FORBIDDEN'));

      // Delete own drop
      final deleted = await notifier.deleteDrop('test-post-1');
      expect(deleted, isTrue);
      expect(container.read(postsRepositoryProvider).any((p) => p.id == 'test-post-1'), isFalse);
    });

    test('loadMoreFriendsFeed safely handles offline / mock mode and keyset boundaries (P8-01)', () async {
      final addedCount = await notifier.loadMoreFriendsFeed(pageSize: 10);
      // In offline / unauthenticated test environment, gracefully returns 0 without crashing or duplicating state
      expect(addedCount, equals(0));
      expect(notifier.hasMoreRemoteDrops, isTrue);
    });

    test('ExifSanitizer strips APP1 EXIF GPS metadata from JPEG byte payloads (P8-02)', () {
      // Construct synthetic JPEG with SOI (0xFFD8) + APP1 EXIF (0xFFE1) with GPS payload + SOS (0xFFDA)
      final fakeGpsPayload = [
        0xFF, 0xD8, // SOI
        0xFF, 0xE1, // APP1 marker (EXIF/GPS)
        0x00, 0x08, // length: 8 bytes (including length bytes)
        0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
        0xFF, 0xDA, // SOS (Start of Scan)
        0x00, 0x02,
        0xAA, 0xBB, // entropy-coded image data
        0xFF, 0xD9, // EOI (End of Image)
      ];

      final rawBytes = Uint8List.fromList(fakeGpsPayload);
      expect(ExifSanitizer.hasExifGps(rawBytes), isTrue);

      final sanitized = ExifSanitizer.stripExif(rawBytes);
      expect(ExifSanitizer.hasExifGps(sanitized), isFalse);

      // Verify sanitized bytes still have valid SOI and SOS markers
      expect(sanitized[0], equals(0xFF));
      expect(sanitized[1], equals(0xD8));
      expect(sanitized.contains(0xE1), isFalse);
    });

    test('AppLogger.validateImagePath enforces 5 MB limit and MIME format restrictions (P8-02)', () {
      // 1. Valid JPEG under 5 MB
      final valid = AppLogger.validateImagePath('sample.jpg', byteLength: 2 * 1024 * 1024);
      expect(valid, isNull);

      // 2. Reject image > 5 MB
      final tooLarge = AppLogger.validateImagePath('heavy.jpg', byteLength: 6 * 1024 * 1024);
      expect(tooLarge, isNotNull);
      expect(tooLarge!.code, equals('IMAGE_TOO_LARGE'));
      expect(tooLarge.message, contains('5 MB maximum'));

      // 3. Reject unsupported executable or file extension
      final invalidType = AppLogger.validateImagePath('malicious.exe', byteLength: 1024);
      expect(invalidType, isNotNull);
      expect(invalidType!.code, equals('INVALID_IMAGE_TYPE'));
    });

    test('reactToPost toggles reactions and updates reactionsCount optimistically without mutating savesCount (P8-04, VAL-06)', () async {
      final initialPost = notifier.state.firstWhere((p) => p.id == 'drop_tash_1');
      final initialReactions = initialPost.reactionsCount;
      final initialSaves = initialPost.savesCount;
      expect(initialPost.userReaction, isNull);

      // React with heart
      await notifier.reactToPost('drop_tash_1', reaction: 'heart');
      final reactedPost = notifier.state.firstWhere((p) => p.id == 'drop_tash_1');
      expect(reactedPost.userReaction, equals('heart'));
      expect(reactedPost.reactionsCount, equals(initialReactions + 1));
      expect(reactedPost.savesCount, equals(initialSaves)); // Decoupled!

      // Toggle off by reacting with heart again
      await notifier.reactToPost('drop_tash_1', reaction: 'heart');
      final unreactedPost = notifier.state.firstWhere((p) => p.id == 'drop_tash_1');
      expect(unreactedPost.userReaction, isNull);
      expect(unreactedPost.reactionsCount, equals(initialReactions));
      expect(unreactedPost.savesCount, equals(initialSaves));

      // React with fire
      await notifier.reactToPost('drop_tash_1', reaction: 'fire');
      final firePost = notifier.state.firstWhere((p) => p.id == 'drop_tash_1');
      expect(firePost.userReaction, equals('fire'));
      expect(firePost.reactionsCount, equals(initialReactions + 1));
      expect(firePost.savesCount, equals(initialSaves));
    });

    test('addCommentToPost validates length and caches comments for authorized drops (P8-04)', () async {
      // 1. Empty comment rejected
      final emptyErr = await notifier.addCommentToPost('drop_tash_1', '   ');
      expect(emptyErr, isNotNull);
      expect(emptyErr!.code, equals('INVALID_COMMENT'));

      // 2. >300 char comment rejected
      final tooLongErr = await notifier.addCommentToPost('drop_tash_1', 'A' * 301);
      expect(tooLongErr, isNotNull);
      expect(tooLongErr!.code, equals('INVALID_COMMENT'));

      // 3. Valid comment accepted
      final validErr = await notifier.addCommentToPost('drop_tash_1', 'Great cardamom bun recommendation!');
      expect(validErr, isNull);

      final comments = await notifier.fetchCommentsForPost('drop_tash_1');
      expect(comments.isNotEmpty, isTrue);
      expect(comments.any((c) => c.body == 'Great cardamom bun recommendation!'), isTrue);
    });
  });
}
