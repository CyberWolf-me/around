import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_place_model.dart';
import 'places_repository.dart';

final savedPlacesProvider = NotifierProvider<SavedPlacesNotifier, List<String>>(SavedPlacesNotifier.new);

class SavedPlacesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ['kettle', 'sable', 'castellan'];

  bool isSaved(String placeId) => state.contains(placeId);

  void toggleSave(String placeId) {
    if (state.contains(placeId)) {
      state = state.where((id) => id != placeId).toList();
    } else {
      state = [...state, placeId];
    }
  }

  void remove(String placeId) {
    state = state.where((id) => id != placeId).toList();
  }
}

final friendPlansProvider = Provider<List<FriendPlanModel>>((ref) {
  final placesRepo = ref.watch(placesRepositoryProvider);
  return [
    FriendPlanModel(
      id: 'p1',
      placeId: 'kettle',
      placeName: placesRepo.getPlaceById('kettle')?.name ?? 'Kettle & Loaf',
      attendeeInitials: const ['NH', 'TV'],
      scheduleTime: 'Sat 10:00 AM',
    ),
    FriendPlanModel(
      id: 'p2',
      placeId: 'castellan',
      placeName: placesRepo.getPlaceById('castellan')?.name ?? 'Castellan',
      attendeeInitials: const ['AL'],
      scheduleTime: 'Fri 7:30 PM',
    ),
  ];
});
