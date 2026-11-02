import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/posts_repository.dart';
import 'package:around_app/data/services/outbox_service.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  group('OutboxService Offline Queue & Exponential Backoff Tests (P10-02)', () {
    late ProviderContainer container;

    setUp(() async {
      await StorageService.clearAll();
      await OutboxService.clearAllPending();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial outbox is empty', () {
      expect(OutboxService.getPendingDrops(), isEmpty);
      expect(container.read(outboxCountProvider), equals(0));
    });

    test('queueDrop enqueues pending drop and updates outboxCount', () async {
      final drop = PendingDrop(
        id: 'offline_drop_1',
        idempotencyKey: 'idem_drop_1',
        placeId: 'breadly',
        placeName: 'Breadly Bakery',
        placeCategory: 'Café',
        placeAddress: '24 Taras Shevchenko',
        note: 'Fresh sourdough',
        createdAt: DateTime.now(),
      );

      final queued = await OutboxService.queueDrop(drop);
      expect(queued, isTrue);

      final drops = OutboxService.getPendingDrops();
      expect(drops.length, equals(1));
      expect(drops.first.id, equals('offline_drop_1'));
      expect(drops.first.idempotencyKey, equals('idem_drop_1'));
    });

    test('queueDrop rejects duplicate drop with identical idempotencyKey', () async {
      final drop1 = PendingDrop(
        id: 'drop_id_a',
        idempotencyKey: 'idem_unique_123',
        placeId: 'breadly',
        placeName: 'Breadly Bakery',
        placeCategory: 'Café',
        placeAddress: '24 Taras Shevchenko',
        note: 'First attempt',
        createdAt: DateTime.now(),
      );

      final drop2 = PendingDrop(
        id: 'drop_id_b',
        idempotencyKey: 'idem_unique_123',
        placeId: 'breadly',
        placeName: 'Breadly Bakery',
        placeCategory: 'Café',
        placeAddress: '24 Taras Shevchenko',
        note: 'Duplicate retry',
        createdAt: DateTime.now(),
      );

      final firstQueued = await OutboxService.queueDrop(drop1);
      expect(firstQueued, isTrue);

      final secondQueued = await OutboxService.queueDrop(drop2);
      expect(secondQueued, isFalse);

      final pending = OutboxService.getPendingDrops();
      expect(pending.length, equals(1));
      expect(pending.first.id, equals('drop_id_a'));
    });

    test('isReadyForRetry respects exponential backoff delay and max retry bounds', () {
      final initialDrop = PendingDrop(
        id: 'drop_backoff_1',
        placeId: 'ecorn',
        placeName: 'Ecorn Café',
        placeCategory: 'Bakery',
        placeAddress: 'Tashkent',
        note: 'Testing backoff',
        createdAt: DateTime.now(),
        retryCount: 0,
        lastAttemptAt: null,
      );

      // Null lastAttemptAt is immediately ready
      expect(OutboxService.isReadyForRetry(initialDrop), isTrue);

      // Retry 1: base delay is 2 * 2^1 = 4 seconds
      final now = DateTime.now();
      final retry1Recent = initialDrop.copyWith(
        retryCount: 1,
        lastAttemptAt: now.subtract(const Duration(seconds: 2)),
      );
      expect(OutboxService.isReadyForRetry(retry1Recent, now: now), isFalse);

      final retry1Elapsed = initialDrop.copyWith(
        retryCount: 1,
        lastAttemptAt: now.subtract(const Duration(seconds: 5)),
      );
      expect(OutboxService.isReadyForRetry(retry1Elapsed, now: now), isTrue);

      // Max retries (5) is permanently capped
      final cappedDrop = initialDrop.copyWith(
        retryCount: OutboxService.maxRetryAttempts,
        lastAttemptAt: now.subtract(const Duration(days: 1)),
      );
      expect(OutboxService.isReadyForRetry(cappedDrop, now: now), isFalse);
    });

    test('incrementRetry increases retryCount and records attempt timestamp', () async {
      final drop = PendingDrop(
        id: 'drop_incr_1',
        placeId: 'steam',
        placeName: 'Steam Bar',
        placeCategory: 'Bar',
        placeAddress: 'Tashkent',
        note: 'Steampunk drinks',
        createdAt: DateTime.now(),
      );

      await OutboxService.queueDrop(drop);
      expect(OutboxService.getPendingDrops().first.retryCount, equals(0));

      await OutboxService.incrementRetry('drop_incr_1');
      final updated = OutboxService.getPendingDrops().first;
      expect(updated.retryCount, equals(1));
      expect(updated.lastAttemptAt, isNotNull);
    });

    test('drainOutboxWithNotifier flushes pending drops into PostsNotifier', () async {
      final postsNotifier = container.read(postsRepositoryProvider.notifier);

      final drop = PendingDrop(
        id: 'drop_drain_1',
        placeId: 'kitobxon',
        placeName: 'Kitobxon Bookshop',
        placeCategory: 'Books',
        placeAddress: 'Tashkent',
        note: 'Quiet afternoon reading',
        audience: 'public',
        createdAt: DateTime.now(),
      );

      await OutboxService.queueDrop(drop);
      expect(OutboxService.getPendingDrops().length, equals(1));

      final syncedCount = await OutboxService.drainOutboxWithNotifier(postsNotifier);
      expect(syncedCount, equals(1));
      expect(OutboxService.getPendingDrops(), isEmpty);

      // Verify drop is in posts repository
      final posts = container.read(postsRepositoryProvider);
      expect(posts.any((p) => p.placeId == 'kitobxon' && p.note == 'Quiet afternoon reading'), isTrue);
    });

    test('removePendingDrop deletes drop by ID', () async {
      final drop = PendingDrop(
        id: 'drop_del_1',
        placeId: 'bnb',
        placeName: 'BNB',
        placeCategory: 'Bar',
        placeAddress: 'Tashkent',
        note: 'Cocktail hour',
        createdAt: DateTime.now(),
      );

      await OutboxService.queueDrop(drop);
      expect(OutboxService.getPendingDrops().length, equals(1));

      await OutboxService.removePendingDrop('drop_del_1');
      expect(OutboxService.getPendingDrops(), isEmpty);
    });
  });
}
