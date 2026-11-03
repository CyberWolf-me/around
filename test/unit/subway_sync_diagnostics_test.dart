import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/subway_sync_diagnostics_service.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SubwaySyncDiagnosticsService service;

  setUp(() async {
    await StorageService.init();
    await StorageService.clearAll();
    service = SubwaySyncDiagnosticsService();
    service.reset();
  });

  tearDown(() async {
    await StorageService.clearAll();
  });

  group('P23-04: SubwaySyncDiagnosticsService Unit Tests', () {
    test('initializes with zero metrics and 0.0 cache hit ratio', () {
      expect(service.totalRequests, equals(0));
      expect(service.cacheHitRatio, equals(0.0));
      expect(service.averageSyncRecoveryLatencyMs, equals(0));

      final snapshot = service.getSnapshot();
      expect(snapshot.cacheHits, equals(0));
      expect(snapshot.cacheMisses, equals(0));
      expect(snapshot.totalSubwaySessions, equals(0));
    });

    test('records cache hits and misses and calculates hit ratio', () {
      service.recordCacheHit('asset_breadly_1');
      service.recordCacheHit('asset_breadly_2');
      service.recordCacheHit('asset_bnb_1');
      service.recordCacheMiss('asset_chorsu_1');

      expect(service.totalRequests, equals(4));
      expect(service.cacheHitRatio, equals(0.75)); // 3 / 4 = 75%
    });

    test('tracks subway commute offline duration accurately', () async {
      final startTime = DateTime(2026, 11, 3, 10, 0, 0);
      final endTime = DateTime(2026, 11, 3, 10, 18, 30); // 18.5 minutes = 1110s

      service.recordSubwayCommuteStart(startTime);
      final duration = await service.recordSubwayCommuteEnd(endTime);

      expect(duration, equals(1110));
      final snapshot = service.getSnapshot();
      expect(snapshot.totalSubwaySessions, equals(1));
      expect(snapshot.cumulativeOfflineSeconds, equals(1110));
    });

    test('tracks sync recovery latency and calculates rolling average', () async {
      await service.recordSyncRecovery(itemsSynced: 3, latencyMs: 200);
      await service.recordSyncRecovery(itemsSynced: 1, latencyMs: 400);

      expect(service.averageSyncRecoveryLatencyMs, equals(300));
      final snapshot = service.getSnapshot();
      expect(snapshot.totalItemsSynced, equals(4));
      expect(snapshot.averageSyncRecoveryLatencyMs, equals(300));
    });

    test('serializes and deserializes snapshot to/from JSON cleanly', () {
      const original = SubwaySyncDiagnosticsSnapshot(
        cacheHits: 12,
        cacheMisses: 3,
        cacheHitRatio: 0.8,
        totalSubwaySessions: 2,
        cumulativeOfflineSeconds: 1500,
        averageSyncRecoveryLatencyMs: 250,
        totalItemsSynced: 5,
      );

      final json = original.toJson();
      final restored = SubwaySyncDiagnosticsSnapshot.fromJson(json);

      expect(restored.cacheHits, equals(12));
      expect(restored.cacheMisses, equals(3));
      expect(restored.cacheHitRatio, equals(0.8));
      expect(restored.totalSubwaySessions, equals(2));
      expect(restored.cumulativeOfflineSeconds, equals(1500));
      expect(restored.averageSyncRecoveryLatencyMs, equals(250));
      expect(restored.totalItemsSynced, equals(5));
    });
  });
}
