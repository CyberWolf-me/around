import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/telegram_share_service.dart';
import '../../../core/services/weekly_digest_engine.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Provider providing the active WeeklyDigest for Tashkent.
final weeklyDigestProvider = Provider<WeeklyDigest>((ref) {
  final placesRepo = ref.watch(placesRepositoryProvider);
  final drops = ref.watch(postsRepositoryProvider);
  final densityAsync = ref.watch(districtDensityProvider);

  final places = placesRepo.getAllPlaces();
  final densities = densityAsync.asData?.value ?? const <DistrictDensityModel>[];

  return WeeklyDigestEngine.generateWeeklyDigest(
    drops: drops,
    places: places,
    districtDensities: densities,
  );
});

/// Tactile Weekly Rhythm Feed Banner mounted at the top of the feed (`P15-01`).
/// Activates dynamically during Tashkent weekend windows (Friday 16:00 – Sunday 23:59),
/// summarizing neighborhood momentum and providing an instant friend coordination sheet.
class WeeklyDigestBanner extends ConsumerWidget {
  final bool forceVisible;
  final DateTime? simulatedTime;
  final ValueChanged<String>? onInviteCopied;

  const WeeklyDigestBanner({
    super.key,
    this.forceVisible = false,
    this.simulatedTime,
    this.onInviteCopied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = simulatedTime ?? DateTime.now();
    final isWeekend = WeeklyDigestEngine.isWeekendWindow(now);

    if (!isWeekend && !forceVisible) {
      return const SizedBox.shrink();
    }

    final digest = ref.watch(weeklyDigestProvider);
    final lang = ref.watch(appLocaleProvider);

    final isFriday = now.weekday == DateTime.friday;
    final badgeLabel = isFriday ? '🔥 FRIDAY NIGHT RHYTHM' : '☕ WEEKEND DISCOVERY';

    return Container(
      key: const Key('weekly_digest_banner'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [AppColors.shadowFloating],
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.6), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.selection();
            _showCoordinationSheet(context, ref, digest, lang);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.orange, width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔥', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeLabel,
                              style: GoogleFonts.spaceMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '📍 ${digest.topDistrict}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.butter,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        digest.getPrompt(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCoordinationSheet(
    BuildContext context,
    WidgetRef ref,
    WeeklyDigest digest,
    String lang,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        final inviteMessage = digest.generateWeekendInviteMessage(lang);
        final trending = digest.trendingVenue;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tashkent Weekend Digest',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.orangeSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📍 ${digest.topDistrict}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  digest.getPrompt(lang),
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink2,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                if (trending != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 20, color: AppColors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trending.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${trending.category} · ${trending.district}',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 11,
                                  color: AppColors.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${trending.ratingAvg}★',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: BouncingWidget(
                        scaleFactor: 0.95,
                        onTap: () async {
                          HapticService.selection();
                          onInviteCopied?.call(inviteMessage);
                          try {
                            await Clipboard.setData(ClipboardData(text: inviteMessage));
                          } catch (_) {}
                          if (bottomSheetContext.mounted) {
                            Navigator.pop(bottomSheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Weekend invite copied! Share with friends.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          key: const Key('btn_copy_weekend_invite'),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.paper2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.copy, size: 15, color: AppColors.ink),
                              const SizedBox(width: 6),
                              Text(
                                'Copy Invite',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BouncingWidget(
                        scaleFactor: 0.95,
                        onTap: () async {
                          HapticService.medium();
                          final shareUri = TelegramShareService.buildShareUri(
                            url: 'https://around.tashkent.app',
                            text: inviteMessage,
                          );
                          try {
                            await launchUrl(shareUri, mode: LaunchMode.externalApplication);
                          } catch (_) {}
                          if (bottomSheetContext.mounted) {
                            Navigator.pop(bottomSheetContext);
                          }
                        },
                        child: Container(
                          key: const Key('btn_telegram_weekend_invite'),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'Gather on Telegram',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
