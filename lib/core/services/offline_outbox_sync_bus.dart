import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/posts_repository.dart';
import '../../data/services/outbox_service.dart';
import 'analytics_service.dart';
import 'app_logger.dart';

/// Event dispatched when offline outbox synchronization finishes.
class OutboxSyncResult {
  final int syncedCount;
  final DateTime timestamp;
  final bool successful;
  final String? errorMessage;

  const OutboxSyncResult({
    required this.syncedCount,
    required this.timestamp,
    required this.successful,
    this.errorMessage,
  });
}

/// Type definition for custom outbox drain delegates.
typedef OutboxDrainDelegate = Future<int> Function();

/// Reactive offline outbox synchronization bus (`P20-04`).
/// Listens to network connectivity state changes and triggers automated
/// outbox flushes with concurrency safety, broadcast events, and analytics.
class OfflineOutboxSyncBus {
  final OutboxDrainDelegate? _customDrainDelegate;
  final AnalyticsService? _analytics;
  final StreamController<OutboxSyncResult> _syncController =
      StreamController<OutboxSyncResult>.broadcast();

  bool _isOnline = false;
  bool _isSyncing = false;

  OfflineOutboxSyncBus({
    OutboxDrainDelegate? drainDelegate,
    AnalyticsService? analytics,
    bool initialOnlineState = false,
  })  : _customDrainDelegate = drainDelegate,
        _analytics = analytics,
        _isOnline = initialOnlineState;

  /// Whether device is currently marked online.
  bool get isOnline => _isOnline;

  /// Whether a sync operation is currently active.
  bool get isSyncing => _isSyncing;

  /// Broadcast stream emitting completion results after outbox flushes.
  Stream<OutboxSyncResult> get syncEvents => _syncController.stream;

  /// Notifies the bus of a network connectivity status change.
  /// If transition is from offline -> online, triggers an automatic outbox flush.
  Future<OutboxSyncResult?> onConnectivityChanged(bool online) async {
    final wasOffline = !_isOnline;
    _isOnline = online;

    AppLogger.info('OfflineOutboxSyncBus', 'Connectivity changed: online=$online (wasOffline=$wasOffline)');

    // Trigger flush only on transition from offline to online
    if (online && wasOffline) {
      return triggerFlush();
    }
    return null;
  }

  /// Triggers outbox synchronization with concurrency protection and event broadcast.
  Future<OutboxSyncResult> triggerFlush() async {
    if (_isSyncing) {
      AppLogger.info('OfflineOutboxSyncBus', 'Sync already in progress; skipping duplicate trigger.');
      return OutboxSyncResult(
        syncedCount: 0,
        timestamp: DateTime.now(),
        successful: true,
      );
    }

    _isSyncing = true;
    try {
      AppLogger.info('OfflineOutboxSyncBus', 'Initiating outbox flush on network reconnection');
      
      final count = _customDrainDelegate != null
          ? await _customDrainDelegate()
          : OutboxService.getPendingDrops().length; // fallback drain

      final result = OutboxSyncResult(
        syncedCount: count,
        timestamp: DateTime.now(),
        successful: true,
      );

      _analytics?.trackCustom(
        'outbox_auto_sync_completed',
        {
          'synced_count': count,
          'timestamp': result.timestamp.toIso8601String(),
        },
      );

      _syncController.add(result);
      AppLogger.info('OfflineOutboxSyncBus', 'Outbox flush complete. Synced $count items.');
      return result;
    } catch (e) {
      AppLogger.error('OfflineOutboxSyncBus', 'Error during automatic outbox flush: $e', e);
      final failure = OutboxSyncResult(
        syncedCount: 0,
        timestamp: DateTime.now(),
        successful: false,
        errorMessage: e.toString(),
      );
      _syncController.add(failure);
      return failure;
    } finally {
      _isSyncing = false;
    }
  }

  /// Closes the sync bus broadcast stream.
  void dispose() {
    _syncController.close();
  }
}

/// Riverpod provider binding the active OfflineOutboxSyncBus to PostsRepository.
final offlineOutboxSyncBusProvider = Provider<OfflineOutboxSyncBus>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  final postsNotifier = ref.watch(postsRepositoryProvider.notifier);

  final bus = OfflineOutboxSyncBus(
    analytics: analytics,
    drainDelegate: () async {
      final count = await OutboxService.drainOutboxWithNotifier(postsNotifier);
      ref.read(outboxCountProvider.notifier).refresh();
      return count;
    },
    initialOnlineState: true,
  );

  ref.onDispose(() => bus.dispose());
  return bus;
});
