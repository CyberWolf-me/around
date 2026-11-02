import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_logger.dart';

/// Cached asset entry tracking payload bytes, access timestamps, and size for LRU eviction.
class CachedAsset {
  final String key;
  final List<int> bytes;
  final String mimeType;
  final DateTime cachedAt;
  DateTime lastAccessedAt;
  int accessCount;

  CachedAsset({
    required this.key,
    required this.bytes,
    this.mimeType = 'image/jpeg',
    DateTime? cachedAt,
    DateTime? lastAccessedAt,
    this.accessCount = 1,
  })  : cachedAt = cachedAt ?? DateTime.now(),
        lastAccessedAt = lastAccessedAt ?? DateTime.now();

  int get byteSize => bytes.length;
}

/// In-memory LRU cache with capacity bounding and offline placeholder fallback
/// optimized for intermittent connectivity during Tashkent subway commutes.
class LowBandwidthCacheService {
  final int maxEntries;
  final int maxBytes;

  final Map<String, CachedAsset> _cache = {};
  int _totalBytes = 0;
  bool _subwayOfflineMode = false;

  LowBandwidthCacheService({
    this.maxEntries = 100,
    this.maxBytes = 10 * 1024 * 1024, // 10MB
  });

  /// Whether subway/low-connectivity offline mode is active.
  bool get isSubwayOfflineMode => _subwayOfflineMode;

  /// Toggles subway offline mode.
  void setSubwayOfflineMode(bool enabled) {
    _subwayOfflineMode = enabled;
    AppLogger.info(
      'LowBandwidthCacheService',
      'Subway offline mode ${enabled ? "ENABLED" : "DISABLED"}',
    );
  }

  /// Number of cached items currently in memory.
  int get count => _cache.length;

  /// Total size of cached assets in bytes.
  int get totalBytes => _totalBytes;

  /// All cached keys.
  List<String> get keys => _cache.keys.toList();

  /// Checks if asset is cached.
  bool has(String key) => _cache.containsKey(key);

  /// Retrieves cached asset and updates LRU timestamp.
  CachedAsset? get(String key) {
    final asset = _cache[key];
    if (asset != null) {
      asset.lastAccessedAt = DateTime.now();
      asset.accessCount++;
      return asset;
    }
    return null;
  }

  /// Stores asset bytes with LRU eviction enforcement.
  void put(
    String key,
    List<int> bytes, {
    String mimeType = 'image/jpeg',
  }) {
    if (bytes.length > maxBytes) {
      AppLogger.warn(
        'LowBandwidthCacheService',
        'Asset $key exceeds maximum cache capacity (${bytes.length} > $maxBytes), skipping',
      );
      return;
    }

    // Remove existing if replacing
    if (_cache.containsKey(key)) {
      evict(key);
    }

    // Evict LRU items while over entry count or byte limit
    while ((_cache.length >= maxEntries || (_totalBytes + bytes.length > maxBytes)) &&
        _cache.isNotEmpty) {
      _evictLRU();
    }

    final asset = CachedAsset(
      key: key,
      bytes: bytes,
      mimeType: mimeType,
    );

    _cache[key] = asset;
    _totalBytes += asset.byteSize;
  }

  /// Evicts a specific key from cache.
  bool evict(String key) {
    final asset = _cache.remove(key);
    if (asset != null) {
      _totalBytes -= asset.byteSize;
      return true;
    }
    return false;
  }

  /// Clears all cached items.
  void clear() {
    _cache.clear();
    _totalBytes = 0;
  }

  /// Returns reliable local placeholder asset path when offline or asset is missing.
  String getFallbackPlaceholder(String category) {
    final normalized = category.toLowerCase().trim();
    if (normalized.contains('cafe') || normalized.contains('coffee') || normalized.contains('tea')) {
      return 'assets/placeholders/cafe_placeholder.png';
    }
    if (normalized.contains('food') ||
        normalized.contains('restaurant') ||
        normalized.contains('plov') ||
        normalized.contains('osh')) {
      return 'assets/placeholders/food_placeholder.png';
    }
    if (normalized.contains('culture') ||
        normalized.contains('art') ||
        normalized.contains('museum') ||
        normalized.contains('theatre') ||
        normalized.contains('architecture')) {
      return 'assets/placeholders/culture_placeholder.png';
    }
    if (normalized.contains('park') ||
        normalized.contains('nature') ||
        normalized.contains('garden') ||
        normalized.contains('green')) {
      return 'assets/placeholders/park_placeholder.png';
    }
    if (normalized.contains('night') ||
        normalized.contains('bar') ||
        normalized.contains('lounge') ||
        normalized.contains('music')) {
      return 'assets/placeholders/nightlife_placeholder.png';
    }
    return 'assets/placeholders/venue_placeholder.png';
  }

  /// Finds and removes the least-recently-accessed entry.
  void _evictLRU() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.lastAccessedAt.isBefore(oldestTime)) {
        oldestTime = entry.value.lastAccessedAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      evict(oldestKey);
    }
  }
}

/// Global Riverpod provider for low bandwidth asset caching.
final lowBandwidthCacheServiceProvider =
    Provider<LowBandwidthCacheService>((ref) => LowBandwidthCacheService());
