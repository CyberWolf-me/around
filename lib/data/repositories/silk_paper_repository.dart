import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/silk_paper_calligraphy_engine.dart';
import '../services/supabase_service.dart';

/// Result from reserving a silk paper & calligraphy workshop seat.
class PaperWorkshopResult {
  final bool success;
  final bool alreadyReserved;
  final String atelierSlug;
  final String scriptId;
  final int xpAwarded;
  final int availableSeats;
  final String? errorMessage;

  const PaperWorkshopResult({
    required this.success,
    required this.alreadyReserved,
    required this.atelierSlug,
    required this.scriptId,
    required this.xpAwarded,
    required this.availableSeats,
    this.errorMessage,
  });

  factory PaperWorkshopResult.fromMap(Map<String, dynamic> map) {
    return PaperWorkshopResult(
      success: map['success'] as bool? ?? false,
      alreadyReserved: map['already_reserved'] as bool? ?? false,
      atelierSlug: map['atelier_slug'] as String? ?? '',
      scriptId: map['script_id'] as String? ?? 'nastaliq',
      xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 35,
      availableSeats: (map['available_seats'] as num?)?.toInt() ?? 0,
      errorMessage: map['error'] as String?,
    );
  }
}

/// Repository for Tashkent Mulberry Silk Paper & Calligraphy Manuscript Ateliers.
class SilkPaperRepository {
  final SilkPaperCalligraphyEngine _engine;

  SilkPaperRepository({SilkPaperCalligraphyEngine? engine})
      : _engine = engine ?? SilkPaperCalligraphyEngine();

  SilkPaperCalligraphyEngine get engine => _engine;

  /// Fetches all published ateliers and masterclasses.
  Future<List<SilkPaperAtelier>> getAteliers() async {
    if (!SupabaseService.isInitialized) {
      return _engine.ateliers;
    }

    try {
      final res = await SupabaseService.client
          .from('silk_paper_ateliers')
          .select('id, slug, name, district, master_name, century_tradition, mulberry_variety, burnish_stone_type, supported_scripts, workshop_price_uzs, available_seats, max_seats, latitude, longitude')
          .eq('is_published', true)
          .order('name', ascending: true);

      if (res.isEmpty) {
        return _engine.ateliers;
      }

      final ateliers = <SilkPaperAtelier>[];
      for (final row in res) {
        final scriptsRaw = (row['supported_scripts'] as List<dynamic>? ?? [])
            .map((s) => CalligraphyScript.fromId(s.toString()))
            .toList();

        final atelier = SilkPaperAtelier(
          id: row['slug'] as String,
          name: row['name'] as String? ?? '',
          district: row['district'] as String? ?? '',
          masterName: row['master_name'] as String? ?? '',
          centuryTradition: row['century_tradition'] as String? ?? '',
          mulberryVariety: row['mulberry_variety'] as String? ?? '',
          burnishStoneType: row['burnish_stone_type'] as String? ?? '',
          latitude: (row['latitude'] as num?)?.toDouble() ?? 41.311081,
          longitude: (row['longitude'] as num?)?.toDouble() ?? 69.240562,
          supportedScripts: scriptsRaw,
          workshopPriceUzs: (row['workshop_price_uzs'] as num?)?.toInt() ?? 150000,
          availableMasterclasses: (row['available_seats'] as num?)?.toInt() ?? 4,
          maxCapacity: (row['max_seats'] as num?)?.toInt() ?? 8,
        );
        ateliers.add(atelier);
      }
      return ateliers;
    } catch (e) {
      AppLogger.warn('SilkPaper', 'Failed to load silk paper ateliers from Supabase: $e', e);
      return _engine.ateliers;
    }
  }

  /// Fetches user's active paper workshop reservations.
  Future<List<PaperWorkshopReservation>> getUserReservations() async {
    if (!SupabaseService.isInitialized) {
      return [
        PaperWorkshopReservation(
          atelierId: 'atelier-chorsu-mulberry',
          script: CalligraphyScript.nastaliq,
          bookedAt: DateTime.now(),
          xpEarned: 35,
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
          .from('user_silk_paper_workshops')
          .select('id, user_id, script_id, xp_awarded, status, created_at, silk_paper_ateliers(slug)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final reservations = <PaperWorkshopReservation>[];
      for (final row in res) {
        final atelierRow = row['silk_paper_ateliers'] as Map<String, dynamic>?;
        final atelierSlug = atelierRow != null ? (atelierRow['slug'] as String? ?? '') : '';

        reservations.add(
          PaperWorkshopReservation(
            atelierId: atelierSlug,
            script: CalligraphyScript.fromId(row['script_id'] as String? ?? 'nastaliq'),
            bookedAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
            xpEarned: (row['xp_awarded'] as num?)?.toInt() ?? 35,
            status: row['status'] as String? ?? 'confirmed',
          ),
        );
      }
      return reservations;
    } catch (e) {
      AppLogger.warn('SilkPaper', 'Failed to fetch user paper workshop reservations: $e', e);
      return [];
    }
  }

  /// Reserves masterclass seat via Security Definer RPC.
  Future<PaperWorkshopResult> reserveWorkshop({
    required String atelierSlug,
    required CalligraphyScript script,
  }) async {
    if (!SupabaseService.isInitialized) {
      final atelier = _engine.findAtelierById(atelierSlug);
      if (atelier == null) {
        return PaperWorkshopResult(
          success: false,
          alreadyReserved: false,
          atelierSlug: atelierSlug,
          scriptId: script.id,
          xpAwarded: 0,
          availableSeats: 0,
          errorMessage: 'Atelier not found.',
        );
      }

      return PaperWorkshopResult(
        success: true,
        alreadyReserved: false,
        atelierSlug: atelierSlug,
        scriptId: script.id,
        xpAwarded: 35,
        availableSeats: atelier.availableMasterclasses > 0
            ? atelier.availableMasterclasses - 1
            : 0,
      );
    }

    try {
      final response = await SupabaseService.client.rpc(
        'reserve_silk_paper_workshop',
        params: {
          'p_atelier_slug': atelierSlug,
          'p_script_id': script.id,
        },
      );

      if (response == null) {
        return PaperWorkshopResult(
          success: false,
          alreadyReserved: false,
          atelierSlug: atelierSlug,
          scriptId: script.id,
          xpAwarded: 0,
          availableSeats: 0,
          errorMessage: 'RPC response was null.',
        );
      }

      final map = Map<String, dynamic>.from(response as Map);
      return PaperWorkshopResult.fromMap(map);
    } catch (e) {
      AppLogger.error('SilkPaper', 'Failed to execute reserve_silk_paper_workshop RPC: $e', e);
      return PaperWorkshopResult(
        success: false,
        alreadyReserved: false,
        atelierSlug: atelierSlug,
        scriptId: script.id,
        xpAwarded: 0,
        availableSeats: 0,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Riverpod Providers for Silk Paper & Calligraphy Ateliers.
final silkPaperRepositoryProvider = Provider<SilkPaperRepository>((ref) {
  final engine = ref.watch(silkPaperCalligraphyEngineProvider);
  return SilkPaperRepository(engine: engine);
});

final silkPaperAteliersProvider = FutureProvider<List<SilkPaperAtelier>>((ref) {
  final repository = ref.watch(silkPaperRepositoryProvider);
  return repository.getAteliers();
});

final userSilkPaperWorkshopsProvider =
    FutureProvider<List<PaperWorkshopReservation>>((ref) {
  final repository = ref.watch(silkPaperRepositoryProvider);
  return repository.getUserReservations();
});
