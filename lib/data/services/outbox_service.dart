import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../models/post_model.dart';
import '../repositories/posts_repository.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class PendingDrop {
  final String id;
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

  const PendingDrop({
    required this.id,
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
  });

  Map<String, dynamic> toJson() => {
        'id': id,
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
      };

  factory PendingDrop.fromJson(Map<String, dynamic> json) => PendingDrop(
        id: json['id'] as String,
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

  static Future<void> queueDrop(PendingDrop drop) async {
    final current = getPendingDrops();
    final updated = [...current, drop];
    await StorageService.setString(_kOutboxDropsKey, jsonEncode(updated.map((d) => d.toJson()).toList()));
    AppLogger.info('OutboxService', 'Queued drop for place ${drop.placeId} in offline outbox (total: ${updated.length})');
  }

  static Future<void> removePendingDrop(String id) async {
    final current = getPendingDrops();
    final updated = current.where((d) => d.id != id).toList();
    await StorageService.setString(_kOutboxDropsKey, jsonEncode(updated.map((d) => d.toJson()).toList()));
  }

  /// Flushes pending offline drops when network is restored (Sprint 3).
  static Future<int> drainOutbox(WidgetRef ref) async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) {
      return 0;
    }

    final drops = getPendingDrops();
    if (drops.isEmpty) return 0;

    int syncedCount = 0;
    AppLogger.info('OutboxService', 'Starting outbox drain for ${drops.length} queued drops');

    for (final drop in drops) {
      try {
        final audienceEnum = drop.audience == 'public' ? PostAudience.public : PostAudience.friends;
        final failure = await ref.read(postsRepositoryProvider.notifier).publishDrop(
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
          AppLogger.warn('OutboxService', 'Failed to drain drop ${drop.id}: ${failure.message}');
          break; // Stop draining if error is transient network failure
        }
      } catch (e) {
        AppLogger.warn('OutboxService', 'Exception draining drop ${drop.id}', e);
        break;
      }
    }

    ref.read(outboxCountProvider.notifier).refresh();
    return syncedCount;
  }
}
