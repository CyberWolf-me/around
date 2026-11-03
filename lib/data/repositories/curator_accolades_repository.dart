import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/curator_accolades_engine.dart';
import '../services/supabase_service.dart';

class CuratorAccoladesRepository {
  final CuratorAccoladesEngine _engine;

  CuratorAccoladesRepository({CuratorAccoladesEngine? engine})
      : _engine = engine ?? CuratorAccoladesEngine();

  /// Fetches aggregated curator accolades (crowns, seasonal trophies, laurels).
  /// Gracefully falls back to local data when offline or Supabase is uninitialized.
  Future<CuratorAccolades> getCuratorAccolades({String? userId, String? username}) async {
    final targetId = userId ?? SupabaseService.currentUser?.id ?? 'offline_user';
    final targetUsername = username ?? 'tashkent_curator';

    if (!SupabaseService.isInitialized) {
      return _buildOfflineFallback(targetId, targetUsername);
    }

    try {
      final res = await SupabaseService.client.rpc(
        'get_curator_accolades',
        params: userId != null ? {'p_user_id': userId} : null,
      );

      if (res is Map<String, dynamic> && res['success'] == true) {
        final crowns = res['crowns_count'] as int? ?? 0;
        final rawTrophies = res['trophies'] as List? ?? [];
        final rawLaurels = res['laurels'] as List? ?? [];
        final resUsername = res['username'] as String? ?? targetUsername;

        final trophies = <CuratorAccoladeTrophy>[];
        for (final item in rawTrophies) {
          if (item is Map<String, dynamic>) {
            trophies.add(CuratorAccoladeTrophy.fromJson(item));
          }
        }

        final laurels = <CuratorAccoladeLaurel>[];
        for (final item in rawLaurels) {
          if (item is Map<String, dynamic>) {
            laurels.add(CuratorAccoladeLaurel.fromJson(item));
          }
        }

        return _engine.buildAccolades(
          userId: targetId,
          username: resUsername,
          crownsCount: crowns,
          trophies: trophies,
          laurels: laurels,
        );
      }

      return _buildOfflineFallback(targetId, targetUsername);
    } catch (e) {
      AppLogger.warn('CuratorAccoladesRepository', 'Failed to fetch curator accolades RPC, using fallback', e);
      return _buildOfflineFallback(targetId, targetUsername);
    }
  }

  CuratorAccolades _buildOfflineFallback(String userId, String username) {
    return _engine.buildAccolades(
      userId: userId,
      username: username,
      crownsCount: 0,
      trophies: [],
      laurels: [],
      totalCuratorXp: 0,
    );
  }
}

final curatorAccoladesRepositoryProvider = Provider<CuratorAccoladesRepository>((ref) {
  final engine = ref.watch(curatorAccoladesEngineProvider);
  return CuratorAccoladesRepository(engine: engine);
});

final curatorAccoladesProvider = FutureProvider.family<CuratorAccolades, String>((ref, userId) async {
  final repo = ref.watch(curatorAccoladesRepositoryProvider);
  return repo.getCuratorAccolades(userId: userId);
});
