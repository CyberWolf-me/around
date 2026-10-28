import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_place_model.dart';
import '../services/storage_service.dart';
import 'places_repository.dart';

final savedPlacesProvider = NotifierProvider<SavedPlacesNotifier, List<String>>(SavedPlacesNotifier.new);

class SavedPlacesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final stored = StorageService.getSavedPlaceIds();
    if (stored != null) return stored;
    return ['breadly', 'bnb', 'ecorn', 'kettle', 'sable'];
  }

  bool isSaved(String placeId) => state.contains(placeId);

  void toggleSave(String placeId) {
    List<String> updated;
    if (state.contains(placeId)) {
      updated = state.where((id) => id != placeId).toList();
    } else {
      updated = [...state, placeId];
    }
    state = updated;
    StorageService.savePlaceIds(updated);
  }

  void remove(String placeId) {
    final updated = state.where((id) => id != placeId).toList();
    state = updated;
    StorageService.savePlaceIds(updated);
  }
}

final friendPlansProvider = Provider<List<FriendPlanModel>>((ref) {
  final placesRepo = ref.watch(placesRepositoryProvider);
  return [
    FriendPlanModel(
      id: 'p1',
      placeId: 'breadly',
      placeName: placesRepo.getPlaceById('breadly')?.name ?? 'Breadly Bakery & Café',
      attendeeInitials: const ['KR', 'BA'],
      scheduleTime: 'Sat 10:30 AM',
    ),
    FriendPlanModel(
      id: 'p2',
      placeId: 'steam',
      placeName: placesRepo.getPlaceById('steam')?.name ?? 'Steam Bar & Lounge',
      attendeeInitials: const ['RM', 'JK'],
      scheduleTime: 'Fri 8:00 PM',
    ),
  ];
});
