import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/curator_tour_story_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Audio player card and sequential chapter stepper for curated walking tours.
class CuratorTourPlayerWidget extends StatelessWidget {
  final CuratorTour tour;
  final int activeChapterIndex; // 1-based index
  final bool isPlaying;
  final double chapterProgress; // 0.0 to 1.0
  final Set<String> completedStopIds;
  final VoidCallback? onPlayToggle;
  final ValueChanged<int>? onChapterSelected;
  final VoidCallback? onNavigateToVenue;
  final String locale;

  const CuratorTourPlayerWidget({
    super.key,
    required this.tour,
    this.activeChapterIndex = 1,
    this.isPlaying = false,
    this.chapterProgress = 0.0,
    this.completedStopIds = const {},
    this.onPlayToggle,
    this.onChapterSelected,
    this.onNavigateToVenue,
    this.locale = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final engine = CuratorTourStoryEngine();
    final stops = tour.stops;
    final clampedIndex = activeChapterIndex.clamp(1, stops.isNotEmpty ? stops.length : 1);
    final currentStop = stops.isNotEmpty ? stops[clampedIndex - 1] : null;

    final overallProgress = engine.calculateTourProgress(tour, completedStopIds);
    final chapterHeader = engine.formatChapterProgress(
      clampedIndex,
      stops.length,
      locale: locale,
    );

    final currentSeconds = currentStop != null
        ? currentStop.durationSeconds * chapterProgress.clamp(0.0, 1.0)
        : 0.0;
    final formattedElapsed = _formatTime(currentSeconds.round());
    final formattedTotal = currentStop?.formattedDuration ?? '0:00';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPlaying ? AppColors.orange.withValues(alpha: 0.5) : AppColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tour Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.title,
                        key: const Key('tour_title_text'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'by ${tour.curatorName} • ${tour.district}',
                        key: const Key('tour_curator_byline_text'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tour Overall Progress Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${overallProgress.toStringAsFixed(0)}% Complete',
                    key: const Key('overall_tour_progress_text'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Active Chapter Card
            if (currentStop != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chapterHeader,
                          key: const Key('chapter_progress_header_text'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                            letterSpacing: 0.3,
                          ),
                        ),
                        // Venue pill
                        GestureDetector(
                          key: const Key('navigate_venue_pill'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticService.selection();
                            onNavigateToVenue?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.place_rounded, size: 12, color: AppColors.orange),
                                const SizedBox(width: 3),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    currentStop.venueName,
                                    key: const Key('venue_name_pill_text'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentStop.title,
                      key: const Key('chapter_title_text'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '“${currentStop.transcript}”',
                      key: const Key('chapter_transcript_text'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.ink2,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress Track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: chapterProgress.clamp(0.0, 1.0),
                        backgroundColor: AppColors.borderHairline,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedElapsed,
                          key: const Key('chapter_elapsed_text'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink3,
                          ),
                        ),
                        Text(
                          formattedTotal,
                          key: const Key('chapter_total_text'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Controls: Prev Chapter, Play/Pause, Next Chapter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous button
                IconButton(
                  key: const Key('prev_chapter_button'),
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: clampedIndex > 1 ? AppColors.ink : AppColors.inkLight,
                  iconSize: 28,
                  onPressed: clampedIndex > 1
                      ? () {
                          HapticService.selection();
                          onChapterSelected?.call(clampedIndex - 1);
                        }
                      : null,
                ),
                const SizedBox(width: 14),
                // Play / Pause Circle
                GestureDetector(
                  key: const Key('tour_play_toggle_button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticService.selection();
                    onPlayToggle?.call();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange,
                      boxShadow: [AppColors.shadowTactile],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Next button
                IconButton(
                  key: const Key('next_chapter_button'),
                  icon: const Icon(Icons.skip_next_rounded),
                  color: clampedIndex < stops.length ? AppColors.ink : AppColors.inkLight,
                  iconSize: 28,
                  onPressed: clampedIndex < stops.length
                      ? () {
                          HapticService.selection();
                          onChapterSelected?.call(clampedIndex + 1);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins:${secs < 10 ? '0' : ''}$secs';
  }
}
