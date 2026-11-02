import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/story_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/stories_repository.dart';

class StoryRail extends ConsumerWidget {
  final Function(String placeId) onSelectPlace;

  const StoryRail({super.key, required this.onSelectPlace});

  void _showCreateStoryDialog(BuildContext context, WidgetRef ref) {
    final places = ref.read(placesRepositoryProvider).getAllPlaces();
    String selectedPlace = places.isNotEmpty ? places.first.id : 'breadly';
    final captionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
          title: Text(
            'Share 24h Venue Story',
            style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedPlace,
                items: places
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: GoogleFonts.instrumentSans(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPlace = val);
                },
                decoration: const InputDecoration(labelText: 'Spot'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionCtrl,
                maxLength: 180,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  hintText: 'What is the vibe right now?',
                ),
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
                final place = ref.read(placesRepositoryProvider).getPlaceById(selectedPlace);
                await ref.read(storiesRepositoryProvider.notifier).createStory(
                      placeId: selectedPlace,
                      mediaUrl: place?.heroImageUrl ?? 'assets/images/breadly.jpg',
                      caption: captionCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Share Story'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryViewer(BuildContext context, StoryModel story) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media
              AppImage(
                path: story.mediaUrl,
                fit: BoxFit.cover,
              ),
              // Top gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Bottom gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Header
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.orange,
                      child: Text(
                        story.authorAvatar ?? story.authorName[0],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.authorName,
                            style: GoogleFonts.instrumentSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          Text(
                            story.placeName,
                            style: GoogleFonts.instrumentSans(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Caption & CTA
              Positioned(
                bottom: 22,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (story.caption.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          story.caption,
                          style: GoogleFonts.instrumentSans(color: Colors.white, fontSize: 14, height: 1.35),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onSelectPlace(story.placeId);
                        },
                        icon: const Icon(Icons.place_rounded, size: 16),
                        label: Text('Visit ${story.placeName}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesRepositoryProvider);

    return SizedBox(
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Add Story" button
            return BouncingWidget(
              scaleFactor: 0.92,
              onTap: () => _showCreateStoryDialog(context, ref),
              child: SizedBox(
                width: 62,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.paper2,
                        border: Border.all(color: AppColors.borderMedium, width: 1.5),
                        boxShadow: const [AppColors.shadowSubtle],
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, color: AppColors.ink, size: 22),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add Story',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final story = stories[index - 1];

          return BouncingWidget(
            scaleFactor: 0.92,
            onTap: () => _showStoryViewer(context, story),
            child: SizedBox(
              width: 62,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.orange, AppColors.butter],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.paper,
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: ClipOval(
                        child: AppImage(
                          path: story.mediaUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.placeName.split(' ').first,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
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
