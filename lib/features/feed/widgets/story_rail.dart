import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/story_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/stories_repository.dart';
import '../../../data/services/haptic_service.dart';

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
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ink, width: 2),
          ),
          title: const Text('Add 24h Venue Story', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedPlace,
                items: places
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 13))))
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
                  hintText: 'What is happening right now?',
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: AppColors.paper),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
                height: 160,
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
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.orange,
                      child: Text(
                        story.authorAvatar ?? story.authorName[0],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.authorName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            story.placeName,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Caption & CTA
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (story.caption.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          story.caption,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
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
                        icon: const Icon(Icons.place, size: 16),
                        label: Text('Visit ${story.placeName}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.paper,
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Add Story" button
            return GestureDetector(
              onTap: () {
                HapticService.light();
                _showCreateStoryDialog(context, ref);
              },
              child: SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ink, width: 2, style: BorderStyle.solid),
                        color: AppColors.paper2,
                        boxShadow: const [AppColors.shadowSm],
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: AppColors.ink, size: 24),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Add Story',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5, fontWeight: FontWeight.bold),
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

          return GestureDetector(
            onTap: () {
              HapticService.light();
              _showStoryViewer(context, story);
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
                      border: Border.all(color: AppColors.orange, width: 2.2),
                      color: AppColors.paper,
                      boxShadow: const [AppColors.shadowSm],
                    ),
                    child: ClipOval(
                      child: AppImage(
                        path: story.mediaUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    story.placeName.split(' ').first,
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
