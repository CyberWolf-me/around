import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/tandoor_bakery_engine.dart';
import '../services/supabase_service.dart';

/// Result from reserving fresh bread loaves via RPC.
class BreadReservationResult {
  final bool success;
  final String bakerySlug;
  final String varietyId;
  final int loavesCount;
  final int xpAwarded;
  final int remainingHotLoaves;
  final String? errorMessage;

  const BreadReservationResult({
    required this.success,
    required this.bakerySlug,
    required this.varietyId,
    required this.loavesCount,
    required this.xpAwarded,
    required this.remainingHotLoaves,
    this.errorMessage,
  });

  factory BreadReservationResult.fromMap(Map<String, dynamic> map) {
    return BreadReservationResult(
      success: map['success'] as bool? ?? false,
      bakerySlug: map['bakery_slug'] as String? ?? '',
      varietyId: map['variety_id'] as String? ?? 'obi_non',
      loavesCount: (map['loaves_count'] as num?)?.toInt() ?? 2,
      xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 30,
      remainingHotLoaves: (map['remaining_hot_loaves'] as num?)?.toInt() ?? 0,
      errorMessage: map['error'] as String?,
    );
  }
}

/// Repository for Tashkent Traditional Bread (Non) Guild & Tandoor Bakeries.
class TandoorBakeryRepository {
  final TandoorBakeryEngine _engine;

  TandoorBakeryRepository({TandoorBakeryEngine? engine})
      : _engine = engine ?? TandoorBakeryEngine();

  TandoorBakeryEngine get engine => _engine;

  /// Fetches all published tandoor bakeries.
  Future<List<TandoorBakeryVenue>> getBakeries() async {
    if (!SupabaseService.isInitialized) {
      return _engine.bakeries;
    }

    try {
      final res = await SupabaseService.client
          .from('tandoor_bakeries')
          .select('id, slug, name, district, head_baker, tandoor_clay_origin, daily_batches_count, current_batch_hot_loaves, next_batch_minutes, signature_breads, favorite_chekich, latitude, longitude')
          .eq('is_published', true)
          .order('name', ascending: true);

      if (res.isEmpty) {
        return _engine.bakeries;
      }

      final bakeries = <TandoorBakeryVenue>[];
      for (final row in res) {
        final breadsRaw = (row['signature_breads'] as List<dynamic>? ?? [])
            .map((b) => BreadVariety.fromId(b.toString()))
            .toList();

        final venue = TandoorBakeryVenue(
          id: row['slug'] as String,
          name: row['name'] as String? ?? '',
          district: row['district'] as String? ?? '',
          headBaker: row['head_baker'] as String? ?? '',
          tandoorClayOrigin: row['tandoor_clay_origin'] as String? ?? '',
          dailyBatchesCount: (row['daily_batches_count'] as num?)?.toInt() ?? 12,
          currentBatchHotLoaves: (row['current_batch_hot_loaves'] as num?)?.toInt() ?? 24,
          nextBatchMinutes: (row['next_batch_minutes'] as num?)?.toInt() ?? 8,
          latitude: (row['latitude'] as num?)?.toDouble() ?? 41.311081,
          longitude: (row['longitude'] as num?)?.toDouble() ?? 69.240562,
          signatureBreads: breadsRaw,
          favoriteChekich: ChekichPattern.fromId(
            row['favorite_chekich'] as String? ?? 'sunburst',
          ),
        );
        bakeries.add(venue);
      }
      return bakeries;
    } catch (e) {
      AppLogger.warn('TandoorBakery', 'Failed to load tandoor bakeries from Supabase: $e', e);
      return _engine.bakeries;
    }
  }

  /// Fetches user's active bread batch reservations.
  Future<List<BreadBatchReservation>> getUserReservations() async {
    if (!SupabaseService.isInitialized) {
      return [
        BreadBatchReservation(
          bakeryId: 'bakery-chorsu-kattabog',
          variety: BreadVariety.obiNon,
          loavesCount: 2,
          reservedAt: DateTime.now(),
          xpEarned: 30,
          status: 'confirmed',
        ),
      ];
    }

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final res = await SupabaseService.client
          .from('user_bread_reservations')
          .select('id, user_id, variety_id, loaves_count, xp_awarded, status, created_at, tandoor_bakeries(slug)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final reservations = <BreadBatchReservation>[];
      for (final row in res) {
        final bakeryRow = row['tandoor_bakeries'] as Map<String, dynamic>?;
        final bakerySlug = bakeryRow != null ? (bakeryRow['slug'] as String? ?? '') : '';

        reservations.add(
          BreadBatchReservation(
            bakeryId: bakerySlug,
            variety: BreadVariety.fromId(row['variety_id'] as String? ?? 'obi_non'),
            loavesCount: (row['loaves_count'] as num?)?.toInt() ?? 2,
            reservedAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
            xpEarned: (row['xp_awarded'] as num?)?.toInt() ?? 30,
            status: row['status'] as String? ?? 'confirmed',
          ),
        );
      }
      return reservations;
    } catch (e) {
      AppLogger.warn('TandoorBakery', 'Failed to fetch user bread reservations: $e', e);
      return [];
    }
  }

  /// Reserves hot tandoor bread batch via Security Definer RPC.
  Future<BreadReservationResult> reserveBreadBatch({
    required String bakerySlug,
    required BreadVariety variety,
    int loavesCount = 2,
  }) async {
    if (!SupabaseService.isInitialized) {
      final bakery = _engine.findBakeryById(bakerySlug);
      if (bakery == null) {
        return BreadReservationResult(
          success: false,
          bakerySlug: bakerySlug,
          varietyId: variety.id,
          loavesCount: loavesCount,
          xpAwarded: 0,
          remainingHotLoaves: 0,
          errorMessage: 'Tandoor bakery not found.',
        );
      }

      return BreadReservationResult(
        success: true,
        bakerySlug: bakerySlug,
        varietyId: variety.id,
        loavesCount: loavesCount,
        xpAwarded: 30,
        remainingHotLoaves: bakery.currentBatchHotLoaves >= loavesCount
            ? bakery.currentBatchHotLoaves - loavesCount
            : 0,
      );
    }

    try {
      final response = await SupabaseService.client.rpc(
        'reserve_fresh_bread_batch',
        params: {
          'p_bakery_slug': bakerySlug,
          'p_variety_id': variety.id,
          'p_loaves_count': loavesCount,
        },
      );

      if (response == null) {
        return BreadReservationResult(
          success: false,
          bakerySlug: bakerySlug,
          varietyId: variety.id,
          loavesCount: loavesCount,
          xpAwarded: 0,
          remainingHotLoaves: 0,
          errorMessage: 'RPC response was null.',
        );
      }

      final map = Map<String, dynamic>.from(response as Map);
      return BreadReservationResult.fromMap(map);
    } catch (e) {
      AppLogger.error('TandoorBakery', 'Failed to execute reserve_fresh_bread_batch RPC: $e', e);
      return BreadReservationResult(
        success: false,
        bakerySlug: bakerySlug,
        varietyId: variety.id,
        loavesCount: loavesCount,
        xpAwarded: 0,
        remainingHotLoaves: 0,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Riverpod Providers for Tandoor Bakeries & Bread Guild.
final tandoorBakeryRepositoryProvider = Provider<TandoorBakeryRepository>((ref) {
  final engine = ref.watch(tandoorBakeryEngineProvider);
  return TandoorBakeryRepository(engine: engine);
});

final tandoorBakeriesProvider = FutureProvider<List<TandoorBakeryVenue>>((ref) {
  final repository = ref.watch(tandoorBakeryRepositoryProvider);
  return repository.getBakeries();
});

final userBreadReservationsProvider =
    FutureProvider<List<BreadBatchReservation>>((ref) {
  final repository = ref.watch(tandoorBakeryRepositoryProvider);
  return repository.getUserReservations();
});
