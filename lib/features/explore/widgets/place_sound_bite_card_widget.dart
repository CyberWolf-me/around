import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/place_sound_bite_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Card widget for playing community courtyard whispers and place sound bites.
class PlaceSoundBiteCardWidget extends StatelessWidget {
  final PlaceSoundBite soundBite;
  final bool isPlaying;
  final double playbackProgress; // 0.0 to 1.0
  final VoidCallback? onPlayToggle;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onLikeToggle;
  final bool isLiked;
  final String locale;

  const PlaceSoundBiteCardWidget({
    super.key,
    required this.soundBite,
    this.isPlaying = false,
    this.playbackProgress = 0.0,
    this.onPlayToggle,
    this.onSeek,
    this.onLikeToggle,
    this.isLiked = false,
    this.locale = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final engine = PlaceSoundBiteEngine();
    final clampedProgress = playbackProgress.clamp(0.0, 1.0);
    final elapsedSeconds = soundBite.durationSeconds * clampedProgress;
    final progressString = engine.formatProgress(elapsedSeconds, soundBite.durationSeconds);
    final categoryLabel = soundBite.localizedCategory(locale: locale);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPlaying ? AppColors.orange.withValues(alpha: 0.5) : AppColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Author Header
          Row(
            children: [
              // Avatar circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orangeSubtle,
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  soundBite.authorName.isNotEmpty
                      ? soundBite.authorName.substring(0, 1).toUpperCase()
                      : 'E',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Author & category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      soundBite.authorName,
                      key: const Key('author_name_text'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      categoryLabel,
                      key: const Key('category_label_text'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              // Like action button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticService.selection();
                  onLikeToggle?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLiked
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : AppColors.paper2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isLiked ? AppColors.danger : AppColors.ink3,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${soundBite.likesCount + (isLiked ? 1 : 0)}',
                        key: const Key('sound_bite_likes_text'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLiked ? AppColors.danger : AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Transcription snippet (if present)
          if (soundBite.transcriptionSnippet != null &&
              soundBite.transcriptionSnippet!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“${soundBite.transcriptionSnippet}”',
              key: const Key('transcription_snippet_text'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: AppColors.ink2,
                height: 1.35,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Waveform Bar Visualizer
          SizedBox(
            height: 38,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final amps = soundBite.waveformAmplitudes;
                final barCount = amps.isEmpty ? 1 : amps.length;
                final barWidth = ((constraints.maxWidth - ((barCount - 1) * 3)) / barCount)
                    .clamp(2.0, 10.0);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(barCount, (i) {
                    final normalizedHeight = amps[i].clamp(0.08, 1.0);
                    final barFraction = (i + 1) / barCount;
                    final isBarActive = barFraction <= clampedProgress;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticService.selection();
                        onSeek?.call(i / barCount);
                      },
                      child: Container(
                        width: barWidth,
                        height: 38 * normalizedHeight,
                        decoration: BoxDecoration(
                          color: isBarActive
                              ? AppColors.orange
                              : AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Player controls & timeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    key: const Key('play_pause_button'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticService.selection();
                      onPlayToggle?.call();
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    progressString,
                    key: const Key('timeline_progress_text'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink2,
                    ),
                  ),
                ],
              ),
              // Venue tag pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 12,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 3),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        soundBite.placeName,
                        key: const Key('place_name_pill_text'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
