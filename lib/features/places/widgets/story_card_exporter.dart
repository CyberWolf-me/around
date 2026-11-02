import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/place_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/services/haptic_service.dart';

/// Viral 9:16 Story Card Exporter for Telegram & Instagram Stories (`P14-03`).
/// Renders an editorial vertical story card with venue imagery, drop quote,
/// district metadata, and Around deep link watermark.
class StoryCardExporter extends StatelessWidget {
  final PlaceModel place;
  final PostModel? drop;
  final String? customQuote;
  final VoidCallback? onExport;
  final ValueChanged<String>? onCopyLink;

  const StoryCardExporter({
    super.key,
    required this.place,
    this.drop,
    this.customQuote,
    this.onExport,
    this.onCopyLink,
  });

  String get _shareUrl => 'https://around.tashkent.app/places/${place.slug}';

  @override
  Widget build(BuildContext context) {
    final quoteText = customQuote ?? drop?.note ?? place.description;
    final authorHandle = drop != null ? '@${drop!.authorUsername}' : 'Around Tashkent';

    return Center(
      child: SingleChildScrollView(
        child: Container(
          key: const Key('story_card_exporter_frame'),
          width: 320,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSubtle, width: 1.5),
            boxShadow: const [AppColors.shadowFloating],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 9:16 Aspect ratio story canvas preview
              AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  key: const Key('story_canvas'),
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                  ),
                  child: Stack(
                    children: [
                      // Hero visual background with gradient overlay
                      Positioned.fill(
                        child: AppImage(
                          path: place.heroImageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Canvas content overlay
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Branding & District tag
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.orange,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'AROUND',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '📍 ${place.district}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '@around_tashkent',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // Center/Lower: Venue title and rating
                            Text(
                              place.name,
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${place.category} · ${place.priceTier}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.butter,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 15, color: AppColors.butter),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${place.ratingAvg}★ (${place.ratingCount} reviews)',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Editorial drop quote card
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.paper.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderSubtle, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.format_quote_rounded, size: 15, color: AppColors.orange),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          authorHandle,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '"$quoteText"',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.instrumentSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.ink,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Footer: Deep Link & Discovery CTA
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.link_rounded, size: 14, color: AppColors.mint),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'around.tashkent.app/places/${place.slug}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom export actions
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: BouncingWidget(
                        scaleFactor: 0.95,
                        onTap: () async {
                          HapticService.selection();
                          onCopyLink?.call(_shareUrl);
                          try {
                            await Clipboard.setData(ClipboardData(text: _shareUrl));
                          } catch (_) {}
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Deep link copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          key: const Key('btn_copy_story_link'),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.paper2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.copy, size: 13, color: AppColors.ink),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Copy Link',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BouncingWidget(
                        scaleFactor: 0.95,
                        onTap: () {
                          HapticService.medium();
                          onExport?.call();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Story card exported for Telegram & Instagram Stories!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          key: const Key('btn_export_story_card'),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Share Story',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}
