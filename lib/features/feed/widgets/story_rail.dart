import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/haptic_service.dart';

class StoryRail extends ConsumerWidget {
  final Function(String placeId) onSelectPlace;

  const StoryRail({super.key, required this.onSelectPlace});

  static const List<String> storyPlaceIds = [
    'breadly',
    'bnb',
    'ecorn',
    'tims',
    'chorsu',
    'steam',
    'kitobxon',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesRepo = ref.watch(placesRepositoryProvider);

    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: storyPlaceIds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final placeId = storyPlaceIds[index];
          final place = placesRepo.getPlaceById(placeId);
          if (place == null) return const SizedBox.shrink();

          return GestureDetector(
            onTap: () {
              HapticService.light();
              onSelectPlace(place.id);
            },
            child: SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2),
                      color: AppColors.paper,
                      boxShadow: const [AppColors.shadowSm],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        place.heroImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.paper2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    place.name.split(' ').first,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
