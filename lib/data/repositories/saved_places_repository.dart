import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../models/saved_place_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import 'places_repository.dart';

final savedPlacesProvider = NotifierProvider<SavedPlacesNotifier, List<String>>(SavedPlacesNotifier.new);

final savedPlaceStatusesProvider =
    NotifierProvider<SavedPlaceStatusesNotifier, Map<String, String>>(SavedPlaceStatusesNotifier.new);

class SavedPlaceStatusesNotifier extends Notifier<Map<String, String>> {
  static const Map<String, String> _defaultStatuses = {
    'breadly': 'want_to_go',
    'bnb': 'been',
    'ecorn': 'want_to_go',
    'steam': 'want_to_go',
    'kitobxon': 'been',
  };

  @override
  Map<String, String> build() {
    final stored = StorageService.getSavedPlaceStatuses();
    if (stored.isNotEmpty) return stored;
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      return {};
    }
    return Map<String, String>.from(_defaultStatuses);
  }

  String getStatus(String placeId) {
    final canonical = PlacesRepository.resolveCanonicalId(placeId);
    return state[canonical] ?? state[placeId] ?? 'want_to_go';
  }

  Future<void> setStatus(String placeId, String status) async {
    final canonical = PlacesRepository.resolveCanonicalId(placeId);
    final updated = {...state, canonical: status};
    state = updated;
    await StorageService.savePlaceStatuses(updated);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final dbUuid = ref.read(placesRepositoryProvider).getPlaceById(canonical)?.canonicalUuid;
        if (dbUuid != null) {
          await SupabaseService.client.from('saved_places').upsert({
            'user_id': SupabaseService.currentUser!.id,
            'place_id': dbUuid,
            'status': status,
          });
        }
      } catch (e) {
        AppLogger.warn('SavedPlaceStatusesNotifier', 'Supabase status sync skipped', e);
      }
    }
  }

  Future<void> purgeAllStatuses() async {
    state = {};
    await StorageService.savePlaceStatuses({});
  }
}

class SavedPlacesNotifier extends Notifier<List<String>> {
  static const List<String> defaultTashkentSaved = ['breadly', 'bnb', 'ecorn', 'steam', 'kitobxon'];

  @override
  List<String> build() {
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      Future.microtask(syncRemoteSavedPlaces);
      final stored = StorageService.getSavedPlaceIds();
      return stored ?? [];
    }
    final stored = StorageService.getSavedPlaceIds();
    if (stored != null) return stored;
    return List<String>.from(defaultTashkentSaved);
  }

  /// Hydrates `public.saved_places` from Supabase upon login (`INT-01` / `INT-02`).
  Future<void> syncRemoteSavedPlaces() async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final myUid = SupabaseService.currentUser!.id;
      final rows = await SupabaseService.client
          .from('saved_places')
          .select('place_id, status, places(slug)')
          .eq('user_id', myUid);
      if (rows.isNotEmpty) {
        final ids = <String>[];
        final statuses = Map<String, String>.from(ref.read(savedPlaceStatusesProvider));
        for (final raw in rows.whereType<Map<String, dynamic>>()) {
          final placeMap = raw['places'] is Map ? Map<String, dynamic>.from(raw['places'] as Map) : null;
          final slugOrId = placeMap?['slug']?.toString() ?? raw['place_id']?.toString() ?? '';
          final placeModel = ref.read(placesRepositoryProvider).getPlaceById(slugOrId);
          final canonical = placeModel?.id ?? PlacesRepository.resolveCanonicalId(slugOrId);
          if (canonical.isNotEmpty && !ids.contains(canonical)) {
            ids.add(canonical);
            statuses[canonical] = raw['status']?.toString() ?? 'want_to_go';
          }
        }
        if (ids.isNotEmpty) {
          state = ids;
          await StorageService.savePlaceIds(ids);
          await StorageService.savePlaceStatuses(statuses);
        }
      }
    } catch (e) {
      AppLogger.warn('SavedPlacesNotifier', 'Remote saved_places hydration skipped', e);
    }
  }

  bool isSaved(String placeId) {
    final canonical = PlacesRepository.resolveCanonicalId(placeId);
    return state.contains(canonical) || state.contains(placeId);
  }

  void toggleSave(String placeId, {String defaultStatus = 'want_to_go'}) {
    final canonical = PlacesRepository.resolveCanonicalId(placeId);
    final wasSaved = state.contains(canonical) || state.contains(placeId);
    List<String> updated;
    if (wasSaved) {
      updated = state.where((id) => id != canonical && id != placeId).toList();
    } else {
      updated = [...state, canonical];
      ref.read(savedPlaceStatusesProvider.notifier).setStatus(canonical, defaultStatus);
    }
    state = updated;
    StorageService.savePlaceIds(updated);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      final dbUuid = ref.read(placesRepositoryProvider).getPlaceById(canonical)?.canonicalUuid;
      if (dbUuid != null) {
        Future.microtask(() async {
          try {
            if (wasSaved) {
              await SupabaseService.client
                  .from('saved_places')
                  .delete()
                  .eq('user_id', SupabaseService.currentUser!.id)
                  .eq('place_id', dbUuid);
            } else {
              await SupabaseService.client.from('saved_places').upsert({
                'user_id': SupabaseService.currentUser!.id,
                'place_id': dbUuid,
                'status': defaultStatus,
              });
            }
          } catch (e) {
            AppLogger.warn('SavedPlacesNotifier', 'Supabase saved_places sync skipped', e);
          }
        });
      }
    }
  }

  void remove(String placeId) {
    final canonical = PlacesRepository.resolveCanonicalId(placeId);
    final updated = state.where((id) => id != canonical && id != placeId).toList();
    state = updated;
    StorageService.savePlaceIds(updated);
  }

  Future<void> purgeAllSaved() async {
    state = [];
    await StorageService.savePlaceIds([]);
  }
}

final friendPlansProvider = NotifierProvider<FriendPlansNotifier, List<FriendPlanModel>>(FriendPlansNotifier.new);

class FriendPlansNotifier extends Notifier<List<FriendPlanModel>> {
  @override
  List<FriendPlanModel> build() {
    final stored = StorageService.getStoredPlans();
    if (stored != null && stored.isNotEmpty) return stored;
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      return [];
    }
    final placesRepo = ref.watch(placesRepositoryProvider);
    return [
      FriendPlanModel(
        id: 'p1',
        placeId: 'breadly',
        placeName: placesRepo.getPlaceById('breadly')?.name ?? 'Breadly Bakery & Café',
        attendeeInitials: const ['KR', 'BA'],
        scheduleTime: 'Sat 10:30 AM',
        note: 'Morning sourdough & lavender matcha run',
      ),
      FriendPlanModel(
        id: 'p2',
        placeId: 'steam',
        placeName: placesRepo.getPlaceById('steam')?.name ?? 'Steam Bar & Lounge',
        attendeeInitials: const ['RM', 'JK'],
        scheduleTime: 'Fri 8:00 PM',
        note: 'Vinyl DJ set & pomegranate sours',
      ),
    ];
  }

  Future<void> addPlan({
    required String placeId,
    required String placeName,
    required String scheduleTime,
    required List<String> attendeeInitials,
    String note = '',
  }) async {
    final canonical = PlacesRepository.resolveCanonicalId(placeId);
    final newPlan = FriendPlanModel(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      placeId: canonical,
      placeName: placeName,
      attendeeInitials: attendeeInitials,
      scheduleTime: scheduleTime,
      note: note,
    );
    final updated = [newPlan, ...state];
    state = updated;
    await StorageService.persistPlans(updated);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final dbUuid = ref.read(placesRepositoryProvider).getPlaceById(canonical)?.canonicalUuid;
        if (dbUuid != null) {
          await SupabaseService.client.from('friend_plans').insert({
            'creator_id': SupabaseService.currentUser!.id,
            'place_id': dbUuid,
            'schedule_time': scheduleTime,
            'note': note,
          });
        }
      } catch (e) {
        AppLogger.warn('FriendPlansNotifier', 'Supabase friend_plans sync skipped', e);
      }
    }
  }

  /// Updates the authenticated user's RSVP status (`going` or `declined`) on a shared plan (Phase 4.1).
  Future<void> rsvpToPlan(String planId, String rsvpStatus) async {
    final previousState = state;
    final plan = state.cast<FriendPlanModel?>().firstWhere((p) => p?.id == planId, orElse: () => null);
    if (plan == null) return;

    final isTogglingOff = plan.myRsvp == rsvpStatus;
    final updatedRsvp = isTogglingOff ? null : rsvpStatus;

    state = [
      for (final p in state)
        if (p.id == planId)
          p.copyWith(myRsvp: updatedRsvp, clearMyRsvp: isTogglingOff)
        else
          p,
    ];
    await StorageService.persistPlans(state);

    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      if (isTogglingOff) {
        await SupabaseService.client
            .from('friend_plan_participants')
            .delete()
            .eq('plan_id', planId)
            .eq('user_id', SupabaseService.currentUser!.id);
      } else {
        await SupabaseService.client
            .from('friend_plan_participants')
            .upsert({
              'plan_id': planId,
              'user_id': SupabaseService.currentUser!.id,
              'rsvp_status': rsvpStatus,
              'responded_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      AppLogger.warn('FriendPlansNotifier', 'Supabase plan RSVP sync failed, rolling back', e);
      state = previousState;
      await StorageService.persistPlans(previousState);
    }
  }

  Future<void> removePlan(String id) async {
    final updated = state.where((p) => p.id != id).toList();
    state = updated;
    await StorageService.persistPlans(updated);
  }

  Future<void> purgeAllPlans() async {
    state = [];
    await StorageService.persistPlans([]);
  }
}
