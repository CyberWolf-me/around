import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/place_model.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';

class VenueRowWidget extends ConsumerWidget {
  final PlaceModel place;
  final VoidCallback onTap;

  const VenueRowWidget({
    super.key,
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPlaces = ref.watch(savedPlacesProvider);
    final isSaved = savedPlaces.contains(place.id);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.ink, width: 1.8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [AppColors.shadowSm],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.ink, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: AppImage(
                path: place.heroImageUrl,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            // Venue Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        place.priceTier,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${place.category} · ${place.walkDistanceLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 11, color: AppColors.orange),
                      const SizedBox(width: 3),
                      Text(
                        '${place.ratingAvg}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${place.ratingCount})',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bookmark Action
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 18,
                color: isSaved ? AppColors.orange : AppColors.ink3,
              ),
              onPressed: () {
                HapticService.medium();
                ref.read(savedPlacesProvider.notifier).toggleSave(place.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
