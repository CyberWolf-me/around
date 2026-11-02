import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/explorer_streak_engine.dart';
import '../../../core/services/locale_service.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/posts_repository.dart';

/// Interactive discovery streak progress and milestone award card (`P18-01`).
class StreakProgressCard extends ConsumerWidget {
  final String userId;
  final List<PostModel>? overrideDrops;
  final ExplorerStreakStatus? customStatus;

  const StreakProgressCard({
    super.key,
    required this.userId,
    this.overrideDrops,
    this.customStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PostModel> drops = overrideDrops ?? ref.watch(postsRepositoryProvider);
    final lang = ref.watch(appLocaleProvider);
    final status = customStatus ??
        ExplorerStreakEngine.computeStreak(
          userId: userId,
          drops: drops,
        );

    final streak = status.currentStreakWeeks;
    final nextMilestone = _getNextMilestone(streak);
    final progress = nextMilestone != null ? (streak / nextMilestone).clamp(0.0, 1.0) : 1.0;

    return Container(
      key: const Key('streak_progress_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status.isAtRisk ? AppColors.orange.withValues(alpha: 0.5) : AppColors.borderSubtle,
          width: status.isAtRisk ? 1.5 : 1.0,
        ),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: streak > 0 ? AppColors.orangeSubtle : AppColors.paper2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: streak > 0 ? AppColors.orange : AppColors.borderHairline,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          streak > 0 ? '🔥' : '🧭',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streak WEEKS',
                          style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: streak > 0 ? AppColors.orange : AppColors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    status.getLocalizedBadge(lang),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              if (status.hasDroppedThisWeek)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mintSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.mint),
                  ),
                  child: Text(
                    '✓ Secured',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                )
              else if (status.isAtRisk)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.butterSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.orange),
                  ),
                  child: Text(
                    '⚠️ ${status.daysRemainingInWeek}d left',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Milestone Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.paper2,
              valueColor: AlwaysStoppedAnimation<Color>(
                status.isAtRisk ? AppColors.orange : (streak >= 12 ? AppColors.cobalt : AppColors.orange),
              ),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nextMilestone != null
                    ? '$streak / $nextMilestone weeks to ${_getNextBadgeName(nextMilestone, lang)}'
                    : 'Max Tier Achieved!',
                style: GoogleFonts.instrumentSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink3,
                ),
              ),
              if (status.longestStreakWeeks > 0)
                Text(
                  'Best: ${status.longestStreakWeeks} wks',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Retrospective prompt container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Row(
              children: [
                Icon(
                  status.hasDroppedThisWeek ? Icons.celebration_rounded : Icons.schedule_rounded,
                  size: 16,
                  color: status.hasDroppedThisWeek ? AppColors.mint : AppColors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.getRetrospectivePrompt(lang),
                    style: GoogleFonts.instrumentSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static int? _getNextMilestone(int current) {
    if (current < 2) return 2;
    if (current < 4) return 4;
    if (current < 8) return 8;
    if (current < 12) return 12;
    return null;
  }

  static String _getNextBadgeName(int milestone, String lang) {
    switch (milestone) {
      case 2:
        return 'Trailblazer';
      case 4:
        return 'Explorer';
      case 8:
        return 'Seasoned';
      case 12:
        return 'Luminary';
      default:
        return 'Milestone';
    }
  }
}
