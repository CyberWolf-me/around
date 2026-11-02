import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/storage_service.dart';
import 'analytics_service.dart';
import 'app_logger.dart';

/// Performance metrics for Tashkent subway commutes and low-bandwidth caching.
class SubwaySyncDiagnosticsSnapshot {
  final int cacheHits;
  final int cacheMisses;
  final double cacheHitRatio;
  final int totalSubwaySessions;
  final int cumulativeOfflineSeconds;
  final int averageSyncRecoveryLatencyMs;
  final int totalItemsSynced;

  const SubwaySyncDiagnosticsSnapshot({
    required this.cacheHits,
    required this.cacheMisses,
    required this.cacheHitRatio,
    required this.totalSubwaySessions,
    required this.cumulativeOfflineSeconds,
    required this.averageSyncRecoveryLatencyMs,
    required this.totalItemsSynced,
  });

  Map<String, dynamic> toJson() => {
        'cache_hits': cacheHits,
        'cache_misses': cacheMisses,
        'cache_hit_ratio': cacheHitRatio,
        'total_subway_sessions': totalSubwaySessions,
        'cumulative_offline_seconds': cumulativeOfflineSeconds,
        'avg_sync_latency_ms': averageSyncRecoveryLatencyMs,
        'total_items_synced': totalItemsSynced,
      };

  factory SubwaySyncDiagnosticsSnapshot.fromJson(Map<String, dynamic> json) {
    return SubwaySyncDiagnosticsSnapshot(
      cacheHits: (json['cache_hits'] as num?)?.toInt() ?? 0,
      cacheMisses: (json['cache_misses'] as num?)?.toInt() ?? 0,
      cacheHitRatio: (json['cache_hit_ratio'] as num?)?.toDouble() ?? 0.0,
      totalSubwaySessions: (json['total_subway_sessions'] as num?)?.toInt() ?? 0,
      cumulativeOfflineSeconds: (json['cumulative_offline_seconds'] as num?)?.toInt() ?? 0,
      averageSyncRecoveryLatencyMs: (json['avg_sync_latency_ms'] as num?)?.toInt() ?? 0,
      totalItemsSynced: (json['total_items_synced'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Offline Cache Telemetry & Subway Sync Diagnostics Service (`P23-04`).
/// Monitors cache hit ratio, underground offline duration, and reconnect outbox flush latency.
class SubwaySyncDiagnosticsService {
  static const String _storageKey = 'around_subway_diagnostics_v1';

  final AnalyticsService? _analytics;

  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalSubwaySessions = 0;
  int _cumulativeOfflineSeconds = 0;
  int _totalSyncRecoveryLatencyMs = 0;
  int _syncRecoveryCount = 0;
  int _totalItemsSynced = 0;

  DateTime? _activeCommuteStartTime;

  SubwaySyncDiagnosticsService({AnalyticsService? analytics})
      : _analytics = analytics {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final raw = StorageService.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final snapshot = SubwaySyncDiagnosticsSnapshot.fromJson(json);
      _cacheHits = snapshot.cacheHits;
      _cacheMisses = snapshot.cacheMisses;
      _totalSubwaySessions = snapshot.totalSubwaySessions;
      _cumulativeOfflineSeconds = snapshot.cumulativeOfflineSeconds;
      _totalItemsSynced = snapshot.totalItemsSynced;
      if (snapshot.averageSyncRecoveryLatencyMs > 0) {
        _syncRecoveryCount = 1;
        _totalSyncRecoveryLatencyMs = snapshot.averageSyncRecoveryLatencyMs;
      }
    } catch (e) {
      AppLogger.warn('SubwaySyncDiagnosticsService', 'Failed to load diagnostics from storage', e);
    }
  }

  Future<void> _persist() async {
    final snapshot = getSnapshot();
    await StorageService.setString(_storageKey, jsonEncode(snapshot.toJson()));
  }

  /// Records a successful cache hit.
  void recordCacheHit([String? key]) {
    _cacheHits++;
    _persist();
  }

  /// Records a cache miss requiring network fetching.
  void recordCacheMiss([String? key]) {
    _cacheMisses++;
    _persist();
  }

  /// Begins tracking a subway commute session (offline entry).
  void recordSubwayCommuteStart([DateTime? timestamp]) {
    _activeCommuteStartTime = timestamp ?? DateTime.now();
  }

  /// Concludes a subway commute session (online resurface).
  Future<int> recordSubwayCommuteEnd([DateTime? timestamp]) async {
    if (_activeCommuteStartTime == null) return 0;

    final now = timestamp ?? DateTime.now();
    final durationSeconds = now.difference(_activeCommuteStartTime!).inSeconds.clamp(0, 86400);

    _activeCommuteStartTime = null;
    _totalSubwaySessions++;
    _cumulativeOfflineSeconds += durationSeconds;

    await _persist();

    _analytics?.trackCustom('subway_commute_completed', {
      'duration_seconds': durationSeconds,
      'cumulative_offline_seconds': _cumulativeOfflineSeconds,
      'total_sessions': _totalSubwaySessions,
    });

    return durationSeconds;
  }

  /// Records post-reconnection sync performance.
  Future<void> recordSyncRecovery({
    required int itemsSynced,
    required int latencyMs,
  }) async {
    _syncRecoveryCount++;
    _totalSyncRecoveryLatencyMs += latencyMs;
    _totalItemsSynced += itemsSynced;

    await _persist();

    _analytics?.trackCustom('subway_sync_recovery', {
      'items_synced': itemsSynced,
      'latency_ms': latencyMs,
      'avg_latency_ms': averageSyncRecoveryLatencyMs,
    });
  }

  /// Total request count (hits + misses).
  int get totalRequests => _cacheHits + _cacheMisses;

  /// Cache efficiency ratio (0.0 to 1.0).
  double get cacheHitRatio {
    if (totalRequests == 0) return 0.0;
    return (_cacheHits / totalRequests);
  }

  int get averageSyncRecoveryLatencyMs {
    if (_syncRecoveryCount == 0) return 0;
    return (_totalSyncRecoveryLatencyMs / _syncRecoveryCount).round();
  }

  /// Generates immutable snapshot.
  SubwaySyncDiagnosticsSnapshot getSnapshot() {
    return SubwaySyncDiagnosticsSnapshot(
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      cacheHitRatio: cacheHitRatio,
      totalSubwaySessions: _totalSubwaySessions,
      cumulativeOfflineSeconds: _cumulativeOfflineSeconds,
      averageSyncRecoveryLatencyMs: averageSyncRecoveryLatencyMs,
      totalItemsSynced: _totalItemsSynced,
    );
  }

  /// Resets all in-memory diagnostics for testing.
  void reset() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _totalSubwaySessions = 0;
    _cumulativeOfflineSeconds = 0;
    _totalSyncRecoveryLatencyMs = 0;
    _syncRecoveryCount = 0;
    _totalItemsSynced = 0;
    _activeCommuteStartTime = null;
    StorageService.setString(_storageKey, '');
  }
}

/// Provider for SubwaySyncDiagnosticsService.
final subwaySyncDiagnosticsProvider = Provider<SubwaySyncDiagnosticsService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return SubwaySyncDiagnosticsService(analytics: analytics);
});
