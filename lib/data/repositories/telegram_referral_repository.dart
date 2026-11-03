import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/telegram_deep_link_engine.dart';
import '../services/supabase_service.dart';

class TelegramReferralRepository {
  /// Records a Telegram Mini App launch attribution via Supabase RPC.
  /// Falls back gracefully when offline or unauthenticated.
  Future<Map<String, dynamic>> recordTelegramLaunch({
    required String referrerHandle,
    required TelegramDeepLinkType targetType,
    String? resourceId,
  }) async {
    final cleanRef = referrerHandle.trim();
    final typeName = targetType.name;

    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      // Local fallback for offline simulation or testing
      return {
        'success': true,
        'offline': true,
        'referrer_handle': cleanRef.isNotEmpty ? cleanRef : 'direct',
        'target_type': typeName,
        'resource_id': resourceId,
        'xp_awarded': cleanRef.isNotEmpty && cleanRef != 'direct' ? 10 : 0,
      };
    }

    try {
      final res = await SupabaseService.client.rpc(
        'record_telegram_launch',
        params: {
          'p_referrer_handle': cleanRef.isNotEmpty ? cleanRef : 'direct',
          'p_target_type': typeName,
          'p_resource_id': resourceId?.trim(),
        },
      );

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true, 'data': res};
    } catch (e) {
      AppLogger.warn('TelegramReferralRepository', 'recordTelegramLaunch RPC failed, falling back', e);
      return {
        'success': false,
        'error': e.toString(),
        'referrer_handle': cleanRef,
      };
    }
  }

  /// Fetches recent referral launches for the authenticated user.
  Future<List<Map<String, dynamic>>> getReferralLaunches() async {
    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      return [];
    }

    try {
      final res = await SupabaseService.client
          .from('referral_launches')
          .select('*')
          .order('launched_at', ascending: false)
          .limit(20);

      final launches = <Map<String, dynamic>>[];
      for (final row in res) {
        launches.add(Map<String, dynamic>.from(row));
      }
      return launches;
    } catch (e) {
      AppLogger.warn('TelegramReferralRepository', 'Failed to fetch referral launches', e);
      return [];
    }
  }
}

final telegramReferralRepositoryProvider = Provider<TelegramReferralRepository>((ref) {
  return TelegramReferralRepository();
});

final recentReferralLaunchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(telegramReferralRepositoryProvider);
  return repo.getReferralLaunches();
});
