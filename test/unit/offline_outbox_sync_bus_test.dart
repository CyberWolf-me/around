import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/offline_outbox_sync_bus.dart';
import 'package:around_app/core/services/analytics_service.dart';

void main() {
  group('P20-04: OfflineOutboxSyncBus Unit Tests', () {
    test('initializes with default state', () {
      final bus = OfflineOutboxSyncBus(initialOnlineState: false);
      expect(bus.isOnline, isFalse);
      expect(bus.isSyncing, isFalse);
      bus.dispose();
    });

    test('detects online transition from offline and triggers flush delegation', () async {
      var delegateCallCount = 0;
      final bus = OfflineOutboxSyncBus(
        initialOnlineState: false,
        drainDelegate: () async {
          delegateCallCount++;
          return 3;
        },
      );

      // Transition to online
      final result = await bus.onConnectivityChanged(true);

      expect(bus.isOnline, isTrue);
      expect(delegateCallCount, equals(1));
      expect(result, isNotNull);
      expect(result!.successful, isTrue);
      expect(result.syncedCount, equals(3));

      // Subsequent online event when already online does not re-trigger
      final redundant = await bus.onConnectivityChanged(true);
      expect(redundant, isNull);
      expect(delegateCallCount, equals(1));

      bus.dispose();
    });

    test('going offline updates status and does not trigger flush', () async {
      var delegateCallCount = 0;
      final bus = OfflineOutboxSyncBus(
        initialOnlineState: true,
        drainDelegate: () async {
          delegateCallCount++;
          return 1;
        },
      );

      final result = await bus.onConnectivityChanged(false);

      expect(bus.isOnline, isFalse);
      expect(delegateCallCount, equals(0));
      expect(result, isNull);

      bus.dispose();
    });

    test('dispatches broadcast event with synced items count', () async {
      final bus = OfflineOutboxSyncBus(
        initialOnlineState: false,
        drainDelegate: () async => 5,
      );

      final receivedEvents = <OutboxSyncResult>[];
      final subscription = bus.syncEvents.listen((event) {
        receivedEvents.add(event);
      });

      await bus.triggerFlush();

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(receivedEvents.length, equals(1));
      expect(receivedEvents.first.syncedCount, equals(5));
      expect(receivedEvents.first.successful, isTrue);

      await subscription.cancel();
      bus.dispose();
    });

    test('enforces idempotency and concurrency protection during active flush', () async {
      final completer = Completer<int>();
      var delegateCallCount = 0;

      final bus = OfflineOutboxSyncBus(
        initialOnlineState: true,
        drainDelegate: () {
          delegateCallCount++;
          return completer.future;
        },
      );

      // Start first flush
      final future1 = bus.triggerFlush();
      expect(bus.isSyncing, isTrue);

      // Trigger second flush while first is active
      final future2 = bus.triggerFlush();

      // Resolve delegate
      completer.complete(4);

      final result1 = await future1;
      final result2 = await future2;

      expect(delegateCallCount, equals(1));
      expect(result1.syncedCount, equals(4));
      expect(result2.syncedCount, equals(0)); // skipped duplicate
      expect(bus.isSyncing, isFalse);

      bus.dispose();
    });

    test('handles delegate error gracefully and emits failure event', () async {
      final bus = OfflineOutboxSyncBus(
        initialOnlineState: true,
        drainDelegate: () async {
          throw Exception('Simulated network timeout');
        },
      );

      final receivedEvents = <OutboxSyncResult>[];
      final subscription = bus.syncEvents.listen((event) {
        receivedEvents.add(event);
      });

      final result = await bus.triggerFlush();

      expect(result.successful, isFalse);
      expect(result.syncedCount, equals(0));
      expect(result.errorMessage, contains('Simulated network timeout'));
      expect(bus.isSyncing, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(receivedEvents.length, equals(1));
      expect(receivedEvents.first.successful, isFalse);

      await subscription.cancel();
      bus.dispose();
    });

    test('offlineOutboxSyncBusProvider provides initialized singleton in ProviderContainer', () {
      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(AnalyticsService.instance),
        ],
      );

      final bus = container.read(offlineOutboxSyncBusProvider);
      expect(bus, isNotNull);
      expect(bus.isOnline, isTrue);

      container.dispose();
    });
  });
}
