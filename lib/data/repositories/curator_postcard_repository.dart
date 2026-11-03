import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../services/supabase_service.dart';

class CuratorPostcardRepository {
  /// Records a user's postcard share and awards +25 XP via Supabase RPC.
  /// Falls back gracefully when offline or unauthenticated.
  Future<Map<String, dynamic>> recordPostcardShare({
    required String placeId,
    String? routeId,
    String shareChannel = 'telegram',
    String? receiptNumber,
    String theme = 'paper',
    String aspectRatio = '9:16',
  }) async {
    final cleanPlace = placeId.trim();
    if (cleanPlace.isEmpty) {
      return {'success': false, 'error': 'Place ID cannot be empty'};
    }

    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      // Local fallback for offline simulation or testing
      return {
        'success': true,
        'offline': true,
        'place_id': cleanPlace,
        'route_id': routeId,
        'share_channel': shareChannel,
        'receipt_number': receiptNumber,
        'xp_awarded': 25,
        'curator_xp': 25,
        'curator_level': 1,
        'curator_tier': 'neighborhoodScout',
      };
    }

    try {
      final res = await SupabaseService.client.rpc(
        'record_postcard_share',
        params: {
          'p_place_id': cleanPlace,
          'p_route_id': routeId,
          'p_share_channel': shareChannel,
          'p_receipt_number': receiptNumber,
          'p_theme': theme,
          'p_aspect_ratio': aspectRatio,
        },
      );

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true, 'data': res};
    } catch (e) {
      AppLogger.warn('CuratorPostcardRepository', 'recordPostcardShare RPC call failed, falling back', e);
      return {
        'success': false,
        'error': e.toString(),
        'place_id': cleanPlace,
      };
    }
  }

  /// Fetches recent postcard shares for the authenticated user or friends.
  Future<List<Map<String, dynamic>>> getRecentPostcardShares({int limit = 20}) async {
    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      return [];
    }

    try {
      final res = await SupabaseService.client
          .from('postcard_shares')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);

      final shares = <Map<String, dynamic>>[];
      for (final row in res) {
        shares.add(Map<String, dynamic>.from(row));
      }
      return shares;
    } catch (e) {
      AppLogger.warn('CuratorPostcardRepository', 'Failed to fetch recent postcard shares', e);
      return [];
    }
  }
}

final curatorPostcardRepositoryProvider = Provider<CuratorPostcardRepository>((ref) {
  return CuratorPostcardRepository();
});

final recentPostcardSharesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(curatorPostcardRepositoryProvider);
  return repo.getRecentPostcardShares();
});
