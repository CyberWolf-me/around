import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../models/post_model.dart';
import '../repositories/posts_repository.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class PendingDrop {
  final String id;
  final String idempotencyKey;
  final String placeId;
  final String placeName;
  final String placeCategory;
  final String placeAddress;
  final String? localPhotoPath;
  final String note;
  final int? rating;
  final List<String> tags;
  final String audience;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttemptAt;

  const PendingDrop({
    required this.id,
    String? idempotencyKey,
    required this.placeId,
    required this.placeName,
    required this.placeCategory,
    required this.placeAddress,
    this.localPhotoPath,
    required this.note,
    this.rating,
    this.tags = const [],
    this.audience = 'friends',
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
  }) : idempotencyKey = idempotencyKey ?? id;

  PendingDrop copyWith({
    int? retryCount,
    DateTime? lastAttemptAt,
  }) {
    return PendingDrop(
      id: id,
      idempotencyKey: idempotencyKey,
      placeId: placeId,
      placeName: placeName,
      placeCategory: placeCategory,
      placeAddress: placeAddress,
      localPhotoPath: localPhotoPath,
      note: note,
      rating: rating,
      tags: tags,
      audience: audience,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'idempotencyKey': idempotencyKey,
        'placeId': placeId,
        'placeName': placeName,
        'placeCategory': placeCategory,
        'placeAddress': placeAddress,
        'localPhotoPath': localPhotoPath,
        'note': note,
        'rating': rating,
        'tags': tags,
        'audience': audience,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      };

  factory PendingDrop.fromJson(Map<String, dynamic> json) => PendingDrop(
        id: json['id'] as String,
        idempotencyKey: json['idempotencyKey'] as String? ?? json['id'] as String,
        placeId: json['placeId'] as String,
        placeName: json['placeName'] as String? ?? 'Tashkent Spot',
        placeCategory: json['placeCategory'] as String? ?? 'Café',
        placeAddress: json['placeAddress'] as String? ?? 'Tashkent, Uzbekistan',
        localPhotoPath: json['localPhotoPath'] as String?,
        note: json['note'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt(),
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        audience: json['audience'] as String? ?? 'friends',
        createdAt: DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
        lastAttemptAt: json['lastAttemptAt'] != null ? DateTime.tryParse(json['lastAttemptAt'].toString()) : null,
      );
}

final outboxCountProvider = NotifierProvider<OutboxCountNotifier, int>(OutboxCountNotifier.new);

class OutboxCountNotifier extends Notifier<int> {
  @override
  int build() => OutboxService.getPendingDrops().length;

  void refresh() {
    state = OutboxService.getPendingDrops().length;
  }
}

class OutboxService {
  static const String _kOutboxDropsKey = 'around_pending_outbox_drops';
  static const int maxRetryAttempts = 5;
  static const int baseRetryDelaySeconds = 2;

  static List<PendingDrop> getPendingDrops() {
    final raw = StorageService.getString(_kOutboxDropsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => PendingDrop.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.warn('OutboxService', 'Failed to decode outbox drops', e);
      return [];
    }
  }

  /// Calculates whether a drop is ready for its next retry attempt based on exponential backoff.
  static bool isReadyForRetry(PendingDrop drop, {DateTime? now}) {
    if (drop.retryCount >= maxRetryAttempts) return false;
    if (drop.lastAttemptAt == null) return true;

    final currentTime = now ?? DateTime.now();
    final delaySeconds = math.min(300, baseRetryDelaySeconds * math.pow(2, drop.retryCount).toInt());
    return currentTime.difference(drop.lastAttemptAt!).inSeconds >= delaySeconds;
  }

  /// Queues a pending drop with idempotent deduplication based on idempotencyKey.
  static Future<bool> queueDrop(PendingDrop drop) async {
    final current = getPendingDrops();
    // Prevent duplicate entries for identical idempotency key
    if (current.any((d) => d.idempotencyKey == drop.idempotencyKey)) {
      AppLogger.warn('OutboxService', 'Drop with idempotency key ${drop.idempotencyKey} already queued; skipping duplicate.');
      return false;
    }

    final updated = [...current, drop];
    await StorageService.setString(_kOutboxDropsKey, jsonEncode(updated.map((d) => d.toJson()).toList()));
    AppLogger.info('OutboxService', 'Queued drop for place ${drop.placeId} in offline outbox (total: ${updated.length})');
    return true;
  }

  /// Records a failed sync attempt and increments retry count with timestamp.
  static Future<void> incrementRetry(String id) async {
    final current = getPendingDrops();
    final updated = current.map((d) {
      if (d.id == id) {
        return d.copyWith(
          retryCount: d.retryCount + 1,
          lastAttemptAt: DateTime.now(),
        );
      }
      return d;
    }).toList();
    await StorageService.setString(_kOutboxDropsKey, jsonEncode(updated.map((d) => d.toJson()).toList()));
  }

  static Future<void> removePendingDrop(String id) async {
    final current = getPendingDrops();
    final updated = current.where((d) => d.id != id).toList();
    await StorageService.setString(_kOutboxDropsKey, jsonEncode(updated.map((d) => d.toJson()).toList()));
  }

  static Future<void> clearAllPending() async {
    await StorageService.removeString(_kOutboxDropsKey);
  }

  /// Flushes pending offline drops using a PostsNotifier instance.
  static Future<int> drainOutboxWithNotifier(PostsNotifier notifier) async {
    if (SupabaseService.isInitialized && !SupabaseService.isAuthenticated) {
      return 0;
    }

    final drops = getPendingDrops();
    if (drops.isEmpty) return 0;

    int syncedCount = 0;
    AppLogger.info('OutboxService', 'Starting outbox drain for ${drops.length} queued drops');

    for (final drop in drops) {
      // Respect exponential backoff delay
      if (!isReadyForRetry(drop)) {
        AppLogger.info('OutboxService', 'Drop ${drop.id} backoff not elapsed (attempt ${drop.retryCount}); skipping for now');
        continue;
      }

      try {
        final audienceEnum = drop.audience == 'public' ? PostAudience.public : PostAudience.friends;
        final failure = await notifier.publishDrop(
          placeId: drop.placeId,
          placeName: drop.placeName,
          placeCategory: drop.placeCategory,
          placeAddress: drop.placeAddress,
          note: drop.note,
          audience: audienceEnum,
          rating: drop.rating,
          tags: drop.tags,
          mediaPath: drop.localPhotoPath,
        );

        if (failure == null) {
          await removePendingDrop(drop.id);
          syncedCount++;
          AppLogger.info('OutboxService', 'Successfully drained outbox drop ${drop.id}');
        } else {
          await incrementRetry(drop.id);
          AppLogger.warn('OutboxService', 'Failed to drain drop ${drop.id}: ${failure.message} (retry ${drop.retryCount + 1})');
          break; // Stop draining if network/server is unavailable
        }
      } catch (e) {
        await incrementRetry(drop.id);
        AppLogger.warn('OutboxService', 'Exception draining drop ${drop.id}', e);
        break;
      }
    }

    return syncedCount;
  }

  /// Flushes pending offline drops when network is restored.
  static Future<int> drainOutbox(WidgetRef ref) async {
    final count = await drainOutboxWithNotifier(ref.read(postsRepositoryProvider.notifier));
    ref.read(outboxCountProvider.notifier).refresh();
    return count;
  }
}
