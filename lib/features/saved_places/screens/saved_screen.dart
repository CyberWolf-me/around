import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/place_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  String _activeFilter = 'All';

  void _showAddPlanDialog(List<PlaceModel> allPlaces) {
    String selectedPlaceId = allPlaces.isNotEmpty ? allPlaces.first.id : 'breadly';
    final timeCtrl = TextEditingController(text: 'Sun 11:00 AM');
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ink, width: 2),
          ),
          title: Text('New Plan with Friends', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedPlaceId,
                items: allPlaces
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPlaceId = val);
                },
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(labelText: 'When', hintText: 'e.g. Sat 4:00 PM'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note', hintText: 'e.g. Coffee & study session'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
            ),
            ElevatedButton(
              onPressed: () async {
                final place = ref.read(placesRepositoryProvider).getPlaceById(selectedPlaceId);
                await ref.read(friendPlansProvider.notifier).addPlan(
                      placeId: selectedPlaceId,
                      placeName: place?.name ?? 'Tashkent Venue',
                      scheduleTime: timeCtrl.text.trim().isEmpty ? 'Sat 11:00 AM' : timeCtrl.text.trim(),
                      attendeeInitials: const ['YO', 'KR'],
                      note: noteCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
              child: const Text('Create Plan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedPlaces = ref.watch(savedPlacesProvider);
    final statuses = ref.watch(savedPlaceStatusesProvider);
    final statusNotifier = ref.read(savedPlaceStatusesProvider.notifier);
    final placesRepo = ref.watch(placesRepositoryProvider);
    final friendPlans = ref.watch(friendPlansProvider);

    final List<PlaceModel> allSavedVenues = savedPlaces
        .map((id) => placesRepo.getPlaceById(id))
        .whereType<PlaceModel>()
        .toList();

    final List<PlaceModel> filteredSavedVenues = allSavedVenues.where((place) {
      if (_activeFilter == 'All') return true;
      final status = statuses[place.id] ?? 'want_to_go';
      if (_activeFilter == 'Want to go') return status == 'want_to_go';
      if (_activeFilter == 'Been') return status == 'been';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your shortlist', style: Theme.of(context).textTheme.labelSmall),
            Row(
              children: [
                Text(
                  'Saved',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredSavedVenues.length} places',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: OutlinedButton.icon(
              onPressed: () => _showAddPlanDialog(placesRepo.getAllPlaces()),
              icon: const Icon(Icons.add, size: 14, color: AppColors.ink),
              label: const Text('Plan', style: TextStyle(color: AppColors.ink, fontSize: 11.5, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.ink, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          Row(
            children: ['All', 'Want to go', 'Been'].map((filter) {
              final isSel = _activeFilter == filter;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      setState(() => _activeFilter = filter);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.ink : AppColors.paper2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.ink, width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSel ? AppColors.paper : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (friendPlans.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [AppColors.shadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group, size: 14, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Text(
                        '${friendPlans.length} plans with friends in Tashkent',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...friendPlans.map((plan) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: GestureDetector(
                          onTap: () => context.push('/places/${plan.placeId}'),
                          child: Row(
                            children: [
                              Row(
                                children: plan.attendeeInitials
                                    .map(
                                      (init) => Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: CircleAvatar(
                                          radius: 9,
                                          backgroundColor: AppColors.ink,
                                          child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 7)),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  plan.placeName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  plan.scheduleTime,
                                  style: const TextStyle(color: Colors.white, fontSize: 9.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (filteredSavedVenues.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text('No places in "$_activeFilter".'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/explore'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                    child: const Text('Discover Venues', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            ...filteredSavedVenues.map((PlaceModel place) {
              final currentStatus = statuses[place.id] ?? 'want_to_go';
              final isBeen = currentStatus == 'been';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/places/${place.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.ink, width: 1.8),
                            boxShadow: const [AppColors.shadowSm],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: AppImage(path: place.heroImageUrl, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    Text(
                                      '${place.category} · ${place.walkDistanceLabel}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 10, color: AppColors.orange),
                                        const SizedBox(width: 2),
                                        Text('${place.ratingAvg}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            HapticService.selection();
                                            statusNotifier.setStatus(place.id, isBeen ? 'want_to_go' : 'been');
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isBeen ? AppColors.mint : AppColors.butter,
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: AppColors.ink, width: 1),
                                            ),
                                            child: Text(
                                              isBeen ? '✓ Been' : 'Want to go',
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.ink),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.bookmark, color: AppColors.orange),
                      onPressed: () {
                        HapticService.medium();
                        ref.read(savedPlacesProvider.notifier).remove(place.id);
                      },
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
