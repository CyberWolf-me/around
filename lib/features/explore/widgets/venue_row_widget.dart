import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/bookmark_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/place_model.dart';
import '../../../data/repositories/saved_places_repository.dart';

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

    return BouncingWidget(
      scaleFactor: 0.985,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [AppColors.shadowCard],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: AppImage(
                path: place.heroImageUrl,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
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
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.paper2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          place.priceTier,
                          style: GoogleFonts.spaceMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${place.category} · ${place.walkDistanceLabel}',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 11.5,
                      color: AppColors.ink2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.orange),
                      const SizedBox(width: 3),
                      Text(
                        '${place.ratingAvg}',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${place.ratingCount})',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9.5,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bookmark Action
            BookmarkButton(
              isSaved: isSaved,
              size: 36,
              onToggle: () {
                ref.read(savedPlacesProvider.notifier).toggleSave(place.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
