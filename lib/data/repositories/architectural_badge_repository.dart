import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/architectural_badge_engine.dart';
import '../services/supabase_service.dart';

/// Result from recording an architectural quest stop visit.
class QuestVisitResult {
  final bool success;
  final String questSlug;
  final String stopKey;
  final int visitedCount;
  final int requiredStops;
  final bool isCompleted;
  final bool badgeUnlockedNow;
  final String badgeName;
  final int xpAwarded;
  final String? errorMessage;

  const QuestVisitResult({
    required this.success,
    required this.questSlug,
    required this.stopKey,
    required this.visitedCount,
    required this.requiredStops,
    required this.isCompleted,
    required this.badgeUnlockedNow,
    required this.badgeName,
    required this.xpAwarded,
    this.errorMessage,
  });

  factory QuestVisitResult.fromMap(Map<String, dynamic> map) {
    return QuestVisitResult(
      success: map['success'] as bool? ?? false,
      questSlug: map['quest_slug'] as String? ?? '',
      stopKey: map['stop_key'] as String? ?? '',
      visitedCount: (map['visited_count'] as num?)?.toInt() ?? 0,
      requiredStops: (map['required_stops'] as num?)?.toInt() ?? 0,
      isCompleted: map['is_completed'] as bool? ?? false,
      badgeUnlockedNow: map['badge_unlocked_now'] as bool? ?? false,
      badgeName: map['badge_name'] as String? ?? '',
      xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 0,
      errorMessage: map['error'] as String?,
    );
  }
}

/// Repository for Tashkent architectural badge quests and landmark visits.
class ArchitecturalBadgeRepository {
  final ArchitecturalBadgeEngine _engine;

  ArchitecturalBadgeRepository({ArchitecturalBadgeEngine? engine})
      : _engine = engine ?? ArchitecturalBadgeEngine();

  ArchitecturalBadgeEngine get engine => _engine;

  /// Fetches all available architectural quests.
  Future<List<ArchitecturalQuest>> getQuests() async {
    if (!SupabaseService.isInitialized) {
      return _engine.getAllQuests();
    }

    try {
      final res = await SupabaseService.client
          .from('architectural_quests')
          .select('id, slug, title, badge_name, description, category, badge_icon, badge_accent_color_hex, required_stops_count, xp_reward, curator_quote')
          .eq('is_published', true)
          .order('created_at', ascending: true);

      if (res.isEmpty) {
        return _engine.getAllQuests();
      }

      final quests = <ArchitecturalQuest>[];
      for (final row in res) {
        final questId = row['id'] as String;
        final stopsRes = await SupabaseService.client
            .from('architectural_quest_stops')
            .select('id, place_id, name, district, architectural_style, year_built, architectural_fact, latitude, longitude')
            .eq('quest_id', questId)
            .order('created_at', ascending: true);

        final stops = stopsRes
            .map((s) => QuestStop.fromJson(s))
            .toList();

        quests.add(ArchitecturalQuest(
          id: questId,
          slug: row['slug'] as String? ?? '',
          title: row['title'] as String? ?? '',
          badgeName: row['badge_name'] as String? ?? '',
          description: row['description'] as String? ?? '',
          category: row['category'] as String? ?? 'Modernism',
          badgeIcon: row['badge_icon'] as String? ?? 'heritage',
          badgeAccentColorHex: row['badge_accent_color_hex'] as String? ?? '#D97706',
          requiredStopsCount: (row['required_stops_count'] as num?)?.toInt() ?? 3,
          xpReward: (row['xp_reward'] as num?)?.toInt() ?? 50,
          stops: stops.isNotEmpty ? stops : _findDefaultStops(row['slug'] as String? ?? ''),
          curatorQuote: row['curator_quote'] as String?,
        ));
      }

      return quests.isNotEmpty ? quests : _engine.getAllQuests();
    } catch (e) {
      AppLogger.warn(
        'ArchitecturalBadgeRepository',
        'Failed to query architectural_quests from Supabase, using defaults',
        e,
      );
      return _engine.getAllQuests();
    }
  }

  List<QuestStop> _findDefaultStops(String slug) {
    final defaultQuest = _engine.getQuestById(slug);
    return defaultQuest?.stops ?? [];
  }

  /// Fetches the set of visited stop keys and place IDs for the user.
  Future<Set<String>> getUserVisitedStops({String? userId}) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineVisitedFallback();
    }

    try {
      final targetUserId = userId ?? SupabaseService.client.auth.currentUser?.id;
      if (targetUserId == null) {
        return _buildOfflineVisitedFallback();
      }

      final res = await SupabaseService.client
          .from('user_quest_visits')
          .select('stop_key, place_id')
          .eq('user_id', targetUserId);

      final visited = <String>{};
      for (final row in res) {
        final stopKey = row['stop_key'] as String?;
        if (stopKey != null && stopKey.isNotEmpty) {
          visited.add(stopKey);
          visited.add('stop-$stopKey');
        }
        final placeId = row['place_id'] as String?;
        if (placeId != null && placeId.isNotEmpty) {
          visited.add(placeId);
        }
      }

      return visited.isNotEmpty ? visited : _buildOfflineVisitedFallback();
    } catch (e) {
      AppLogger.warn(
        'ArchitecturalBadgeRepository',
        'Failed to fetch user quest visits from Supabase, using offline fallback',
        e,
      );
      return _buildOfflineVisitedFallback();
    }
  }

  /// Records a landmark stop visit via RPC.
  Future<QuestVisitResult> recordStopVisit(
    String questSlug,
    String stopKey, {
    String? placeId,
  }) async {
    if (!SupabaseService.isInitialized) {
      return QuestVisitResult(
        success: true,
        questSlug: questSlug,
        stopKey: stopKey,
        visitedCount: 1,
        requiredStops: 3,
        isCompleted: false,
        badgeUnlockedNow: false,
        badgeName: 'Modernist Connoisseur',
        xpAwarded: 0,
      );
    }

    try {
      final res = await SupabaseService.client.rpc(
        'record_quest_stop_visit',
        params: {
          'p_quest_slug': questSlug,
          'p_stop_key': stopKey,
          if (placeId != null) 'p_place_id': placeId,
        },
      );

      final map = Map<String, dynamic>.from(res as Map);
      return QuestVisitResult.fromMap(map);
    } catch (e) {
      AppLogger.error(
        'ArchitecturalBadgeRepository',
        'RPC record_quest_stop_visit failed',
        e,
      );
      return QuestVisitResult(
        success: false,
        questSlug: questSlug,
        stopKey: stopKey,
        visitedCount: 0,
        requiredStops: 0,
        isCompleted: false,
        badgeUnlockedNow: false,
        badgeName: '',
        xpAwarded: 0,
        errorMessage: e.toString(),
      );
    }
  }

  Set<String> _buildOfflineVisitedFallback() {
    return {
      'hotel-uzbekistan-canonical',
      'stop-hotel-uzbekistan',
      'hotel-uzbekistan',
      'chorsu-bazaar-canonical',
      'stop-chorsu-dome',
      'chorsu-dome',
    };
  }
}

/// Riverpod provider for ArchitecturalBadgeRepository.
final architecturalBadgeRepositoryProvider = Provider<ArchitecturalBadgeRepository>((ref) {
  final engine = ref.watch(architecturalBadgeEngineProvider);
  return ArchitecturalBadgeRepository(engine: engine);
});

/// Riverpod provider for architectural quests catalog.
final architecturalQuestsProvider = FutureProvider<List<ArchitecturalQuest>>((ref) async {
  final repo = ref.watch(architecturalBadgeRepositoryProvider);
  return repo.getQuests();
});

/// Riverpod provider for user's visited quest stops.
final userQuestVisitedStopsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(architecturalBadgeRepositoryProvider);
  return repo.getUserVisitedStops();
});
