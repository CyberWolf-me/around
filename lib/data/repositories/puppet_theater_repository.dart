import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/puppet_theater_engine.dart';
import '../services/supabase_service.dart';

/// Result from reserving puppet theater tickets via RPC.
class PuppetTicketResult {
  final bool success;
  final String theaterSlug;
  final String performanceId;
  final int seatsCount;
  final int xpAwarded;
  final int remainingSeats;
  final String? errorMessage;

  const PuppetTicketResult({
    required this.success,
    required this.theaterSlug,
    required this.performanceId,
    required this.seatsCount,
    required this.xpAwarded,
    required this.remainingSeats,
    this.errorMessage,
  });

  factory PuppetTicketResult.fromMap(Map<String, dynamic> map) {
    return PuppetTicketResult(
      success: map['success'] as bool? ?? false,
      theaterSlug: map['theater_slug'] as String? ?? '',
      performanceId: map['performance_id'] as String? ?? '',
      seatsCount: (map['seats_count'] as num?)?.toInt() ?? 1,
      xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 35,
      remainingSeats: (map['remaining_seats'] as num?)?.toInt() ?? 0,
      errorMessage: map['error'] as String?,
    );
  }
}

/// Repository for Tashkent State Puppet Theater & Marionette Craft Stages.
class PuppetTheaterRepository {
  final PuppetTheaterEngine _engine;

  PuppetTheaterRepository({PuppetTheaterEngine? engine})
      : _engine = engine ?? PuppetTheaterEngine();

  PuppetTheaterEngine get engine => _engine;

  /// Fetches all published puppet theater stages.
  Future<List<PuppetTheaterStage>> getStages() async {
    if (!SupabaseService.isInitialized) {
      return _engine.stages;
    }

    try {
      final res = await SupabaseService.client
          .from('puppet_theaters')
          .select('id, slug, name, district, chief_master, founded_year, available_seats, max_seats, supported_formats, latitude, longitude')
          .eq('is_published', true)
          .order('name', ascending: true);

      if (res.isEmpty) {
        return _engine.stages;
      }

      final stages = <PuppetTheaterStage>[];
      for (final row in res) {
        final slug = row['slug'] as String? ?? '';
        final defaultStage = _engine.findStageById(slug);

        stages.add(
          PuppetTheaterStage(
            id: slug,
            name: row['name'] as String? ?? '',
            district: row['district'] as String? ?? '',
            chiefMaster: row['chief_master'] as String? ?? '',
            foundedYear: (row['founded_year'] as num?)?.toInt() ?? 1939,
            availableSeats: (row['available_seats'] as num?)?.toInt() ?? 32,
            latitude: (row['latitude'] as num?)?.toDouble() ?? 41.3052,
            longitude: (row['longitude'] as num?)?.toDouble() ?? 69.2618,
            repertoire: defaultStage?.repertoire ?? const [],
            signatureFigures: defaultStage?.signatureFigures ?? const [],
          ),
        );
      }
      return stages;
    } catch (e) {
      AppLogger.warn('PuppetTheater', 'Failed to load puppet stages from Supabase: $e', e);
      return _engine.stages;
    }
  }

  /// Fetches user's active puppet theater ticket reservations.
  Future<List<PuppetTicketReservation>> getUserReservations() async {
    if (!SupabaseService.isInitialized) {
      return [
        PuppetTicketReservation(
          stageId: 'theater-state-puppet-kosmonavtlar',
          performanceId: 'show-polvon-kachal-wedding',
          seatsCount: 2,
          reservedAt: DateTime.now(),
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
          .from('user_puppet_tickets')
          .select('id, user_id, performance_id, seats_count, xp_awarded, status, created_at, puppet_theaters(slug)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final reservations = <PuppetTicketReservation>[];
      for (final row in res) {
        final theaterRow = row['puppet_theaters'] as Map<String, dynamic>?;
        final theaterSlug = theaterRow != null ? (theaterRow['slug'] as String? ?? '') : '';

        reservations.add(
          PuppetTicketReservation(
            stageId: theaterSlug,
            performanceId: row['performance_id'] as String? ?? '',
            seatsCount: (row['seats_count'] as num?)?.toInt() ?? 1,
            reservedAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
            xpEarned: (row['xp_awarded'] as num?)?.toInt() ?? 35,
            status: row['status'] as String? ?? 'confirmed',
          ),
        );
      }
      return reservations;
    } catch (e) {
      AppLogger.warn('PuppetTheater', 'Failed to fetch user puppet tickets: $e', e);
      return [];
    }
  }

  /// Reserves puppet theater tickets via Security Definer RPC.
  Future<PuppetTicketResult> reserveTicket({
    required String theaterSlug,
    required String performanceId,
    int seatsCount = 1,
  }) async {
    if (!SupabaseService.isInitialized) {
      final stage = _engine.findStageById(theaterSlug);
      if (stage == null) {
        return PuppetTicketResult(
          success: false,
          theaterSlug: theaterSlug,
          performanceId: performanceId,
          seatsCount: seatsCount,
          xpAwarded: 0,
          remainingSeats: 0,
          errorMessage: 'Puppet theater stage not found.',
        );
      }

      return PuppetTicketResult(
        success: true,
        theaterSlug: theaterSlug,
        performanceId: performanceId,
        seatsCount: seatsCount,
        xpAwarded: 35,
        remainingSeats: stage.availableSeats >= seatsCount
            ? stage.availableSeats - seatsCount
            : 0,
      );
    }

    try {
      final response = await SupabaseService.client.rpc(
        'reserve_puppet_theater_ticket',
        params: {
          'p_theater_slug': theaterSlug,
          'p_performance_id': performanceId,
          'p_seats_count': seatsCount,
        },
      );

      if (response == null) {
        return PuppetTicketResult(
          success: false,
          theaterSlug: theaterSlug,
          performanceId: performanceId,
          seatsCount: seatsCount,
          xpAwarded: 0,
          remainingSeats: 0,
          errorMessage: 'RPC response was null.',
        );
      }

      final map = Map<String, dynamic>.from(response as Map);
      return PuppetTicketResult.fromMap(map);
    } catch (e) {
      AppLogger.error('PuppetTheater', 'Failed to execute reserve_puppet_theater_ticket RPC: $e', e);
      return PuppetTicketResult(
        success: false,
        theaterSlug: theaterSlug,
        performanceId: performanceId,
        seatsCount: seatsCount,
        xpAwarded: 0,
        remainingSeats: 0,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Riverpod Providers for Puppet Theater Stages & Repertoire.
final puppetTheaterRepositoryProvider = Provider<PuppetTheaterRepository>((ref) {
  final engine = ref.watch(puppetTheaterEngineProvider);
  return PuppetTheaterRepository(engine: engine);
});

final puppetStagesProvider = FutureProvider<List<PuppetTheaterStage>>((ref) {
  final repository = ref.watch(puppetTheaterRepositoryProvider);
  return repository.getStages();
});

final userPuppetTicketsProvider =
    FutureProvider<List<PuppetTicketReservation>>((ref) {
  final repository = ref.watch(puppetTheaterRepositoryProvider);
  return repository.getUserReservations();
});
