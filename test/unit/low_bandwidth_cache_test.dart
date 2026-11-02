import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/low_bandwidth_cache_service.dart';

void main() {
  group('P16-03: LowBandwidthCacheService & Subway Offline Image Store', () {
    late LowBandwidthCacheService cache;

    setUp(() {
      cache = LowBandwidthCacheService(maxEntries: 3, maxBytes: 100);
    });

    test('stores and retrieves cached assets correctly', () {
      final sampleBytes = [1, 2, 3, 4, 5];
      cache.put('place_breadly_cover', sampleBytes, mimeType: 'image/webp');

      expect(cache.has('place_breadly_cover'), isTrue);
      expect(cache.count, equals(1));
      expect(cache.totalBytes, equals(5));

      final retrieved = cache.get('place_breadly_cover');
      expect(retrieved, isNotNull);
      expect(retrieved!.key, equals('place_breadly_cover'));
      expect(retrieved.bytes, equals(sampleBytes));
      expect(retrieved.mimeType, equals('image/webp'));
      expect(retrieved.accessCount, equals(2)); // 1 initial + 1 from get
    });

    test('returns null for cache miss', () {
      expect(cache.has('non_existent_key'), isFalse);
      expect(cache.get('non_existent_key'), isNull);
    });

    test('evicts least recently used item when maxEntries is exceeded', () {
      cache.put('item1', [10, 20]);
      cache.put('item2', [30, 40]);
      cache.put('item3', [50, 60]);

      expect(cache.count, equals(3));
      expect(cache.keys, containsAll(['item1', 'item2', 'item3']));

      // Adding 4th item should evict item1 (oldest)
      cache.put('item4', [70, 80]);

      expect(cache.count, equals(3));
      expect(cache.has('item1'), isFalse);
      expect(cache.has('item2'), isTrue);
      expect(cache.has('item3'), isTrue);
      expect(cache.has('item4'), isTrue);
    });

    test('accessing an item refreshes its LRU priority', () async {
      cache.put('first', [1, 1]);
      cache.put('second', [2, 2]);
      cache.put('third', [3, 3]);

      // Delay briefly and access 'first', making 'second' the least recently used
      await Future<void>.delayed(const Duration(milliseconds: 10));
      cache.get('first');

      // Now add 'fourth' -> should evict 'second', not 'first'
      cache.put('fourth', [4, 4]);

      expect(cache.has('first'), isTrue);
      expect(cache.has('second'), isFalse);
      expect(cache.has('third'), isTrue);
      expect(cache.has('fourth'), isTrue);
    });

    test('evicts items when total bytes exceed maxBytes', () {
      final byteCache = LowBandwidthCacheService(maxEntries: 10, maxBytes: 50);

      byteCache.put('a', List.filled(20, 1)); // 20 bytes
      byteCache.put('b', List.filled(20, 2)); // 20 bytes (total 40)
      expect(byteCache.totalBytes, equals(40));

      // Adding 20 more bytes exceeds 50 bytes max -> should evict 'a'
      byteCache.put('c', List.filled(20, 3));

      expect(byteCache.has('a'), isFalse);
      expect(byteCache.has('b'), isTrue);
      expect(byteCache.has('c'), isTrue);
      expect(byteCache.totalBytes, equals(40));
    });

    test('rejects item larger than maxBytes directly', () {
      final smallCache = LowBandwidthCacheService(maxEntries: 5, maxBytes: 30);
      smallCache.put('huge', List.filled(50, 9));

      expect(smallCache.has('huge'), isFalse);
      expect(smallCache.count, equals(0));
      expect(smallCache.totalBytes, equals(0));
    });

    test('evict and clear operations reset cache metrics', () {
      cache.put('x', [1, 2, 3]);
      cache.put('y', [4, 5, 6]);

      expect(cache.count, equals(2));
      expect(cache.totalBytes, equals(6));

      final evicted = cache.evict('x');
      expect(evicted, isTrue);
      expect(cache.has('x'), isFalse);
      expect(cache.totalBytes, equals(3));

      cache.clear();
      expect(cache.count, equals(0));
      expect(cache.totalBytes, equals(0));
    });

    test('toggles subway offline mode flag', () {
      expect(cache.isSubwayOfflineMode, isFalse);

      cache.setSubwayOfflineMode(true);
      expect(cache.isSubwayOfflineMode, isTrue);

      cache.setSubwayOfflineMode(false);
      expect(cache.isSubwayOfflineMode, isFalse);
    });

    test('returns appropriate category fallback placeholders for offline rendering', () {
      expect(
        cache.getFallbackPlaceholder('Cafe & Bakery'),
        equals('assets/placeholders/cafe_placeholder.png'),
      );
      expect(
        cache.getFallbackPlaceholder('Uzbek Osh Center'),
        equals('assets/placeholders/food_placeholder.png'),
      );
      expect(
        cache.getFallbackPlaceholder('State Art Museum'),
        equals('assets/placeholders/culture_placeholder.png'),
      );
      expect(
        cache.getFallbackPlaceholder('Alisher Navoiy National Park'),
        equals('assets/placeholders/park_placeholder.png'),
      );
      expect(
        cache.getFallbackPlaceholder('Cosmopolitan Lounge Bar'),
        equals('assets/placeholders/nightlife_placeholder.png'),
      );
      expect(
        cache.getFallbackPlaceholder('Unknown Novelty Category'),
        equals('assets/placeholders/venue_placeholder.png'),
      );
    });
  });
}
