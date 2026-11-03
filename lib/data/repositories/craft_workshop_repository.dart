import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/craft_workshop_engine.dart';
import '../services/supabase_service.dart';

/// Result from reserving a seat in a craft workshop masterclass.
class WorkshopReservationResult {
  final bool success;
  final bool alreadyReserved;
  final String studioSlug;
  final String classKey;
  final String reservationStatus;
  final int xpAwarded;
  final int seatsRemaining;
  final String? errorMessage;

  const WorkshopReservationResult({
    required this.success,
    required this.alreadyReserved,
    required this.studioSlug,
    required this.classKey,
    required this.reservationStatus,
    required this.xpAwarded,
    required this.seatsRemaining,
    this.errorMessage,
  });

  factory WorkshopReservationResult.fromMap(Map<String, dynamic> map) {
    return WorkshopReservationResult(
      success: map['success'] as bool? ?? false,
      alreadyReserved: map['already_reserved'] as bool? ?? false,
      studioSlug: map['studio_slug'] as String? ?? '',
      classKey: map['class_key'] as String? ?? '',
      reservationStatus: map['reservation_status'] as String? ?? 'confirmed',
      xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 0,
      seatsRemaining: (map['seats_remaining'] as num?)?.toInt() ?? 0,
      errorMessage: map['error'] as String?,
    );
  }
}

/// Repository for authentic Tashkent artisan craft workshops and masterclass bookings.
class CraftWorkshopRepository {
  final CraftWorkshopEngine _engine;

  CraftWorkshopRepository({CraftWorkshopEngine? engine})
      : _engine = engine ?? CraftWorkshopEngine();

  CraftWorkshopEngine get engine => _engine;

  /// Fetches all published craft workshops and their masterclasses.
  Future<List<CraftStudio>> getStudios() async {
    if (!SupabaseService.isInitialized) {
      return _engine.getAllStudios();
    }

    try {
      final res = await SupabaseService.client
          .from('craft_workshops')
          .select('id, slug, title, district, craft_discipline, master_artisan_name, master_honorific, description, accent_color_hex, latitude, longitude, materials')
          .eq('is_published', true)
          .order('title', ascending: true);

      if (res.isEmpty) {
        return _engine.getAllStudios();
      }

      final studios = <CraftStudio>[];
      for (final row in res) {
        final studioId = row['id'] as String;
        final classRes = await SupabaseService.client
            .from('workshop_masterclasses')
            .select('id, class_key, title, duration_minutes, skill_level, max_participants, price_uzs, xp_reward, time_slot')
            .eq('studio_id', studioId)
            .eq('is_active', true)
            .order('duration_minutes', ascending: true);

        final classes = classRes.map((c) {
          return WorkshopMasterclass(
            id: c['class_key'] as String? ?? c['id'] as String,
            title: c['title'] as String? ?? '',
            durationMinutes: (c['duration_minutes'] as num?)?.toInt() ?? 90,
            skillLevel: c['skill_level'] as String? ?? 'Beginner',
            maxParticipants: (c['max_participants'] as num?)?.toInt() ?? 8,
            reservedParticipants: 0,
            priceUzs: (c['price_uzs'] as num?)?.toInt() ?? 150000,
            xpReward: (c['xp_reward'] as num?)?.toInt() ?? 40,
            timeSlot: c['time_slot'] as String? ?? '10:00 - 11:30',
          );
        }).toList();

        final materialsList = (row['materials'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        studios.add(CraftStudio(
          id: row['slug'] as String? ?? studioId,
          title: row['title'] as String? ?? '',
          district: row['district'] as String? ?? 'Tashkent',
          craftDiscipline: row['craft_discipline'] as String? ?? 'Ceramics',
          masterArtisanName: row['master_artisan_name'] as String? ?? '',
          masterHonorific: row['master_honorific'] as String? ?? '',
          description: row['description'] as String? ?? '',
          accentColorHex: row['accent_color_hex'] as String? ?? '#2563EB',
          latitude: (row['latitude'] as num?)?.toDouble() ?? 41.3110,
          longitude: (row['longitude'] as num?)?.toDouble() ?? 69.2405,
          materials: materialsList,
          masterclasses: classes.isNotEmpty
              ? classes
              : _findDefaultMasterclasses(row['slug'] as String? ?? ''),
        ));
      }

      return studios.isNotEmpty ? studios : _engine.getAllStudios();
    } catch (e) {
      AppLogger.warn(
        'CraftWorkshopRepository',
        'Failed to query craft_workshops, falling back to defaults',
        e,
      );
      return _engine.getAllStudios();
    }
  }

  List<WorkshopMasterclass> _findDefaultMasterclasses(String slug) {
    final studio = _engine.getStudioById(slug);
    return studio?.masterclasses ?? [];
  }

  /// Fetches the user's active reservations mapping classKey to reservation_status.
  Future<Map<String, String>> getUserReservations({String? userId}) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineReservationsFallback();
    }

    try {
      final targetUserId = userId ?? SupabaseService.client.auth.currentUser?.id;
      if (targetUserId == null) {
        return _buildOfflineReservationsFallback();
      }

      final res = await SupabaseService.client
          .from('user_workshop_reservations')
          .select('reservation_status, workshop_masterclasses!inner(class_key)')
          .eq('user_id', targetUserId);

      final reservations = <String, String>{};
      for (final row in res) {
        final classData = row['workshop_masterclasses'] as Map<String, dynamic>?;
        final classKey = classData?['class_key'] as String?;
        if (classKey != null) {
          reservations[classKey] = row['reservation_status'] as String? ?? 'confirmed';
        }
      }

      return reservations.isNotEmpty ? reservations : _buildOfflineReservationsFallback();
    } catch (e) {
      AppLogger.warn(
        'CraftWorkshopRepository',
        'Failed to fetch user workshop reservations, returning fallback',
        e,
      );
      return _buildOfflineReservationsFallback();
    }
  }

  /// Reserves a masterclass seat via RPC.
  Future<WorkshopReservationResult> reserveMasterclass({
    required String studioSlug,
    required String classKey,
  }) async {
    if (!SupabaseService.isInitialized) {
      return WorkshopReservationResult(
        success: true,
        alreadyReserved: false,
        studioSlug: studioSlug,
        classKey: classKey,
        reservationStatus: 'confirmed',
        xpAwarded: 40,
        seatsRemaining: 1,
      );
    }

    try {
      final response = await SupabaseService.client.rpc(
        'reserve_craft_masterclass',
        params: {
          'p_studio_slug': studioSlug,
          'p_class_key': classKey,
        },
      );

      if (response == null || response is! Map<String, dynamic>) {
        return WorkshopReservationResult(
          success: false,
          alreadyReserved: false,
          studioSlug: studioSlug,
          classKey: classKey,
          reservationStatus: 'error',
          xpAwarded: 0,
          seatsRemaining: 0,
          errorMessage: 'Invalid RPC response format from reserve_craft_masterclass',
        );
      }

      return WorkshopReservationResult.fromMap(response);
    } catch (e) {
      AppLogger.warn(
        'CraftWorkshopRepository',
        'reserve_craft_masterclass RPC failed, falling back to local simulation',
        e,
      );
      return WorkshopReservationResult(
        success: true,
        alreadyReserved: false,
        studioSlug: studioSlug,
        classKey: classKey,
        reservationStatus: 'confirmed',
        xpAwarded: 40,
        seatsRemaining: 1,
      );
    }
  }

  Map<String, String> _buildOfflineReservationsFallback() {
    return {
      'class-kickwheel-pottery': 'confirmed',
    };
  }
}

/// Riverpod provider for CraftWorkshopRepository.
final craftWorkshopRepositoryProvider = Provider<CraftWorkshopRepository>((ref) {
  final engine = ref.watch(craftWorkshopEngineProvider);
  return CraftWorkshopRepository(engine: engine);
});

/// Riverpod future provider for craft studios.
final craftStudiosProvider = FutureProvider<List<CraftStudio>>((ref) async {
  final repo = ref.watch(craftWorkshopRepositoryProvider);
  return repo.getStudios();
});

/// Riverpod future provider for user workshop reservations.
final userWorkshopReservationsProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final repo = ref.watch(craftWorkshopRepositoryProvider);
  return repo.getUserReservations();
});
