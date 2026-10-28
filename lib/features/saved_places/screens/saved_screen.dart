import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final savedPlaces = ref.watch(savedPlacesProvider);
    final placesRepo = ref.watch(placesRepositoryProvider);
    final friendPlans = ref.watch(friendPlansProvider);

    final savedVenues = savedPlaces
        .map((id) => placesRepo.getPlaceById(id))
        .whereType<dynamic>()
        .toList();

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
                const Text(
                  'Saved',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'BricolageGrotesque',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${savedPlaces.length} places',
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
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          // Filter Segments
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

          // Shared Plans Box
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

          // Saved Places List
          if (savedVenues.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Text('Your shortlist is empty.'),
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
            ...savedVenues.map((place) => Padding(
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
                                    child: Image.asset(place.heroImageUrl, fit: BoxFit.cover),
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
                                      Row(
                                        children: [
                                          const Icon(Icons.star, size: 10, color: AppColors.orange),
                                          const SizedBox(width: 2),
                                          Text('${place.ratingAvg}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                )),

          const SizedBox(height: 70), // tab clearance
        ],
      ),
    );
  }
}
