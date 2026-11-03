import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/group_crawl_session_engine.dart';
import '../services/supabase_service.dart';

class GroupCrawlRepository {
  Future<GroupCrawlSession?> createSessionRemote({
    required String routeId,
    required String routeTitle,
    required String hostUserId,
    required String hostName,
    required String hostInitials,
    String districtPrefix = 'MRB',
  }) async {
    final localSession = GroupCrawlSessionEngine.createSession(
      routeId: routeId,
      routeTitle: routeTitle,
      hostUserId: hostUserId,
      hostName: hostName,
      hostInitials: hostInitials,
      districtPrefix: districtPrefix,
    );

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client.from('group_crawl_sessions').insert({
          'session_code': localSession.sessionCode,
          'route_id': localSession.routeId,
          'route_title': localSession.routeTitle,
          'host_user_id': localSession.hostUserId,
          'squad_bonus_xp': localSession.squadBonusXp,
        });

        await SupabaseService.client.from('group_crawl_participants').insert({
          'session_code': localSession.sessionCode,
          'user_id': hostUserId,
          'is_host': true,
          'visited_stop_ids': [],
        });
      } catch (e) {
        AppLogger.warn('GroupCrawlRepository', 'Failed to create remote session, running locally', e);
      }
    }
    return localSession;
  }

  Future<GroupCrawlSession?> joinOrUpdateSession({
    required String sessionCode,
    String? currentPlaceId,
  }) async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) {
      return null;
    }

    try {
      final res = await SupabaseService.client.rpc('join_or_update_group_crawl', params: {
        'p_session_code': sessionCode,
        if (currentPlaceId != null) 'p_current_place_id': currentPlaceId,
      });

      if (res is Map && res['success'] == true) {
        final participants = (res['participants'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(CrawlParticipant.fromJson)
                .toList() ??
            [];

        return GroupCrawlSession(
          sessionCode: res['session_code']?.toString() ?? sessionCode,
          routeId: res['route_id']?.toString() ?? '',
          routeTitle: res['route_title']?.toString() ?? '',
          hostUserId: participants.firstWhere((p) => p.isHost, orElse: () => participants.first).userId,
          participants: participants,
          createdAt: DateTime.now(),
          squadBonusXp: (res['squad_bonus_xp'] as num?)?.toInt() ?? 200,
        );
      }
    } catch (e) {
      AppLogger.warn('GroupCrawlRepository', 'joinOrUpdateSession RPC failed', e);
    }
    return null;
  }
}

class ActiveGroupCrawlNotifier extends Notifier<GroupCrawlSession?> {
  @override
  GroupCrawlSession? build() => null;

  void setSession(GroupCrawlSession? session) {
    state = session;
  }
}

final groupCrawlRepositoryProvider = Provider<GroupCrawlRepository>((ref) {
  return GroupCrawlRepository();
});

final activeGroupCrawlProvider = NotifierProvider<ActiveGroupCrawlNotifier, GroupCrawlSession?>(
  ActiveGroupCrawlNotifier.new,
);
